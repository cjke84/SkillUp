#!/bin/sh

set -eu

SKILLUP_ROOT=${SKILLUP_ROOT:-$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)}
SKILLUP_DEFAULT_CONFIG="$SKILLUP_ROOT/config.example.toml"
SKILLUP_DEFAULT_ARTIFACT_DIR="$SKILLUP_ROOT/.skillup-artifacts"
SKILLUP_RESULTS=""

usage() {
  cat <<'EOF'
Usage: publish.sh --source <path> [options]

Options:
  --source <path>        Single skill directory or repository root
  --platforms <csv>      github,xiaping,openclaw,clawhub
  --config <path>        Config file path
  --artifact-dir <path>  Artifact output directory
  --dry-run              Validate and package without remote publishing
  --help                 Show this message
EOF
}

main() {
  SOURCE=""
  PLATFORMS=""
  CONFIG_PATH=""
  ARTIFACT_DIR=""
  DRY_RUN=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --source)
        SOURCE=$2
        shift 2
        ;;
      --platforms)
        PLATFORMS=$2
        shift 2
        ;;
      --config)
        CONFIG_PATH=$2
        shift 2
        ;;
      --artifact-dir)
        ARTIFACT_DIR=$2
        shift 2
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  [ -n "$SOURCE" ] || {
    echo "--source is required" >&2
    usage >&2
    exit 1
  }

  [ -d "$SOURCE" ] || {
    echo "Source directory not found: $SOURCE" >&2
    exit 1
  }

  if [ -z "$CONFIG_PATH" ] && [ -f "$SKILLUP_DEFAULT_CONFIG" ]; then
    CONFIG_PATH=$SKILLUP_DEFAULT_CONFIG
  fi

  if [ -z "$PLATFORMS" ]; then
    PLATFORMS=$(config_get "$CONFIG_PATH" defaults platforms "github,xiaping,openclaw,clawhub")
  fi

  if [ -z "$ARTIFACT_DIR" ]; then
    ARTIFACT_DIR=$(config_get "$CONFIG_PATH" defaults artifact_dir "$SKILLUP_DEFAULT_ARTIFACT_DIR")
  fi
  ARTIFACT_DIR=$(resolve_path "$ARTIFACT_DIR" "$SKILLUP_ROOT")

  mkdir -p "$ARTIFACT_DIR"

  SKILLS=$(discover_skills "$SOURCE")
  if [ -z "$SKILLS" ]; then
    echo "No skills found under $SOURCE" >&2
    exit 1
  fi

  OLD_IFS=$IFS
  IFS='
'
  for skill_dir in $SKILLS; do
    IFS=$OLD_IFS
    process_skill "$skill_dir" "$PLATFORMS" "$CONFIG_PATH" "$ARTIFACT_DIR" "$DRY_RUN"
    IFS='
'
  done
  IFS=$OLD_IFS

  print_summary
}

config_get() {
  config_path=$1
  section=$2
  key=$3
  default_value=$4

  if [ -z "$config_path" ] || [ ! -f "$config_path" ]; then
    printf '%s\n' "$default_value"
    return
  fi

  value=$(awk -v target_section="[$section]" -v target_key="$key" '
    BEGIN { in_section = 0 }
    /^\[[^]]+\]$/ { in_section = ($0 == target_section); next }
    in_section && $0 ~ "^[[:space:]]*" target_key "[[:space:]]*=" {
      sub(/^[^=]*=[[:space:]]*/, "", $0)
      gsub(/^[[:space:]]*"/, "", $0)
      gsub(/"[[:space:]]*$/, "", $0)
      print
      exit
    }
  ' "$config_path")

  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "$default_value"
  fi
}

resolve_path() {
  input_path=$1
  base_dir=$2

  case "$input_path" in
    /*)
      printf '%s\n' "$input_path"
      ;;
    *)
      printf '%s\n' "$base_dir/$input_path"
      ;;
  esac
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

manifest_get() {
  skill_dir=$1
  key=$2
  manifest_path="$skill_dir/manifest.toml"

  if [ ! -f "$manifest_path" ]; then
    return 1
  fi

  awk -v target_key="$key" '
    $0 ~ "^[[:space:]]*" target_key "[[:space:]]*=" {
      sub(/^[^=]*=[[:space:]]*/, "", $0)
      gsub(/^[[:space:]]*"/, "", $0)
      gsub(/"[[:space:]]*$/, "", $0)
      print
      exit
    }
  ' "$manifest_path"
}

frontmatter_get() {
  skill_dir=$1
  key=$2
  skill_md="$skill_dir/SKILL.md"

  awk -v target_key="$key" '
    NR == 1 && $0 != "---" { exit }
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { exit }
    in_frontmatter && $0 ~ "^[[:space:]]*" target_key ":" {
      sub(/^[^:]*:[[:space:]]*/, "", $0)
      gsub(/^[[:space:]]*"/, "", $0)
      gsub(/"[[:space:]]*$/, "", $0)
      print
      exit
    }
  ' "$skill_md"
}

slugify() {
  printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/-\{2,\}/-/g; s/^-//; s/-$//'
}

discover_skills() {
  source_dir=$1

  if [ -f "$source_dir/SKILL.md" ]; then
    printf '%s\n' "$source_dir"
    return
  fi

  find "$source_dir" -mindepth 1 -maxdepth 2 -type f -name 'SKILL.md' | while read -r skill_file; do
    dirname "$skill_file"
  done | sort -u
}

skill_slug() {
  skill_dir=$1
  slug=$(manifest_get "$skill_dir" slug 2>/dev/null || true)
  if [ -z "$slug" ]; then
    slug=$(frontmatter_get "$skill_dir" name 2>/dev/null || true)
  fi
  if [ -z "$slug" ]; then
    slug=$(basename "$skill_dir")
  fi
  slugify "$slug"
}

skill_version() {
  skill_dir=$1
  version=$(manifest_get "$skill_dir" version 2>/dev/null || true)
  if [ -z "$version" ]; then
    version=$(frontmatter_get "$skill_dir" version 2>/dev/null || true)
  fi
  printf '%s\n' "$version"
}

ensure_skill_version() {
  skill_dir=$1
  version=$(skill_version "$skill_dir")
  if [ -z "$version" ]; then
    echo "Missing version metadata for $skill_dir; add version to SKILL.md frontmatter or manifest.toml" >&2
    return 1
  fi
}

validate_skill_dir() {
  skill_dir=$1
  [ -f "$skill_dir/SKILL.md" ] || {
    echo "Missing SKILL.md in $skill_dir" >&2
    return 1
  }
}

package_skill() {
  skill_dir=$1
  artifact_dir=$2
  slug=$(skill_slug "$skill_dir")
  artifact_path="$artifact_dir/$slug.zip"
  parent_dir=$(dirname "$skill_dir")
  skill_name=$(basename "$skill_dir")

  rm -f "$artifact_path"
  (
    cd "$parent_dir"
    zip -qr "$artifact_path" "$skill_name"
  )
  printf '%s\n' "$artifact_path"
}

process_skill() {
  skill_dir=$1
  platforms_csv=$2
  config_path=$3
  artifact_dir=$4
  dry_run=$5

  validate_skill_dir "$skill_dir"
  ensure_skill_version "$skill_dir"
  artifact_path=$(package_skill "$skill_dir" "$artifact_dir")

  OLD_IFS=$IFS
  IFS=','
  for platform in $platforms_csv; do
    IFS=$OLD_IFS
    publish_one "$platform" "$skill_dir" "$artifact_path" "$config_path" "$dry_run"
    IFS=','
  done
  IFS=$OLD_IFS
}

trim() {
  printf '%s' "$1" | awk '{ gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print }'
}

record_result() {
  platform=$1
  skill_dir=$2
  status=$3
  detail=$4
  SKILLUP_RESULTS="${SKILLUP_RESULTS}${platform}|${skill_dir}|${status}|${detail}
"
}

template_render() {
  template=$1
  slug=$2
  version=$3

  printf '%s\n' "$template" | sed \
    -e "s/{slug}/$slug/g" \
    -e "s/{version}/$version/g"
}

publish_one() {
  raw_platform=$1
  skill_dir=$2
  artifact_path=$3
  config_path=$4
  dry_run=$5
  platform=$(trim "$raw_platform")

  case "$platform" in
    github)
      publish_github "$skill_dir" "$artifact_path" "$config_path" "$dry_run"
      ;;
    xiaping)
      publish_xiaping "$skill_dir" "$artifact_path" "$config_path" "$dry_run"
      ;;
    openclaw)
      publish_openclaw "$skill_dir" "$artifact_path" "$config_path" "$dry_run"
      ;;
    clawhub)
      publish_clawhub "$skill_dir" "$artifact_path" "$config_path" "$dry_run"
      ;;
    "")
      ;;
    *)
      record_result "$platform" "$skill_dir" "skipped" "unknown platform"
      ;;
  esac
}

print_summary() {
  printf '%s' "$SKILLUP_RESULTS" | awk -F'|' 'NF >= 4 {
    printf "[%s] %s -> %s (%s)\n", $1, $2, $3, $4
  }'
}

env_or_config() {
  env_name=$1
  config_path=$2
  section=$3
  key=$4
  default_value=$5

  eval "env_value=\${$env_name:-}"
  if [ -n "$env_value" ]; then
    printf '%s\n' "$env_value"
    return
  fi

  config_get "$config_path" "$section" "$key" "$default_value"
}
