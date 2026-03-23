#!/bin/sh

check_xiaping() {
  skill_dir=$1
  config_path=$2

  if ! check_common_platform_requirement "xiaping" "$skill_dir"; then
    return 1
  fi

  category=$(manifest_section_get "$skill_dir" xiaping category 2>/dev/null || true)
  if [ -z "$category" ]; then
    category='["开发辅助"]'
  fi

  allowed_categories=$(curl -sS 'https://xiaping.coze.site/api/categories' 2>/dev/null || true)
  if [ -n "$allowed_categories" ]; then
    valid_category_json=$(python3 - "$allowed_categories" <<'PY'
import json
import sys
payload = json.loads(sys.argv[1])
print(json.dumps(payload.get("data", []), ensure_ascii=False))
PY
)

    for item in $(json_array_each "$category"); do
      if ! json_array_contains "$valid_category_json" "$item"; then
        record_result "xiaping" "$skill_dir" "failed" "invalid Xiaping category: $item"
        return 1
      fi
    done
  fi

  record_result "xiaping" "$skill_dir" "validated" "Xiaping metadata looks valid"
  return 0
}

status_xiaping() {
  skill_dir=$1
  config_path=$2
  local_version=$3

  skill_id=$(manifest_section_get "$skill_dir" xiaping skill_id 2>/dev/null || true)
  if [ -z "$skill_id" ]; then
    skill_id="387c0737-5e5e-4488-990c-5c696e9603f2"
  fi

  response=$(curl -sS "https://xiaping.coze.site/api/skills/$skill_id" 2>/dev/null || true)
  if [ -z "$response" ]; then
    record_result "xiaping" "$skill_dir" "status-unknown" "unable to fetch Xiaping status" "" "$skill_id" "" ""
    printf '[xiaping] %s remote=unknown\n' "$skill_dir"
    return 0
  fi

  remote_version=$(python3 - "$response" <<'PY'
import json
import sys
payload = json.loads(sys.argv[1])
print(payload.get("data", {}).get("current_version", ""))
PY
)
  if [ "$remote_version" = "$local_version" ]; then
    record_result "xiaping" "$skill_dir" "in-sync" "Xiaping version matches local" "https://xiaping.coze.site/skill/$skill_id" "$skill_id" "$remote_version" ""
    printf '[xiaping] %s remote=%s status=in-sync\n' "$skill_dir" "$remote_version"
  else
    record_result "xiaping" "$skill_dir" "out-of-sync" "Xiaping version differs from local" "https://xiaping.coze.site/skill/$skill_id" "$skill_id" "$remote_version" ""
    printf '[xiaping] %s remote=%s status=out-of-sync\n' "$skill_dir" "$remote_version"
  fi
  return 0
}

publish_xiaping() {
  skill_dir=$1
  artifact_path=$2
  config_path=$3
  dry_run=$4

  api_key=$(env_or_config "SKILLUP_XIAPING_API_KEY" "$config_path" xiaping api_key "")
  base_url=$(config_get "$config_path" xiaping base_url "https://xiaping.coze.site")
  upload_path=$(config_get "$config_path" xiaping upload_path "/api/skills")
  name=$(manifest_get "$skill_dir" name 2>/dev/null || true)
  if [ -z "$name" ]; then
    name=$(frontmatter_get "$skill_dir" name 2>/dev/null || true)
  fi
  description=$(manifest_get "$skill_dir" description 2>/dev/null || true)
  version=$(skill_version "$skill_dir")
  trigger=$(manifest_section_get "$skill_dir" xiaping trigger 2>/dev/null || true)
  category=$(manifest_section_get "$skill_dir" xiaping category 2>/dev/null || true)
  tags=$(manifest_section_get "$skill_dir" xiaping tags 2>/dev/null || true)

  if [ -z "$trigger" ]; then
    slug=$(skill_slug "$skill_dir")
    trigger="[\"$name\",\"$slug\"]"
  fi

  if [ -z "$category" ]; then
    category='["开发辅助"]'
  fi

  if [ -z "$tags" ]; then
    tags='["Skill","Automation"]'
  fi

  if [ "$dry_run" -eq 1 ]; then
    record_result "xiaping" "$skill_dir" "dry-run" "would upload $artifact_path to $base_url$upload_path"
    return
  fi

  if [ -z "$api_key" ]; then
    record_result "xiaping" "$skill_dir" "skipped" "missing API key"
    return
  fi

  if [ -z "$name" ] || [ -z "$description" ] || [ -z "$version" ]; then
    record_result "xiaping" "$skill_dir" "failed" "missing name, description, or version metadata"
    return
  fi

  http_code=$(curl -sS -o /tmp/skillup-xiaping-response.json -w '%{http_code}' \
    -X POST "$base_url$upload_path" \
    -H "Authorization: Bearer $api_key" \
    -F "name=$name" \
    -F "description=$description" \
    -F "trigger=$trigger" \
    -F "category=$category" \
    -F "tags=$tags" \
    -F "version=$version" \
    -F "file=@$artifact_path")

  if [ "$http_code" -eq 409 ]; then
    existing_skill_id=$(python3 - <<'PY'
import json
try:
    with open('/tmp/skillup-xiaping-response.json', 'r', encoding='utf-8') as handle:
        payload = json.load(handle)
    print(payload.get('data', {}).get('existing_skill', {}).get('id', ''))
except Exception:
    print('')
PY
)
    if [ -n "$existing_skill_id" ]; then
      upload_code=$(curl -sS -o /tmp/skillup-xiaping-upload-response.json -w '%{http_code}' \
        -X POST "$base_url/api/upload" \
        -H "Authorization: Bearer $api_key" \
        -F "skill_id=$existing_skill_id" \
        -F "changelog=SkillUp $version 自动更新" \
        -F "file=@$artifact_path")

      if [ "$upload_code" -ge 200 ] && [ "$upload_code" -lt 300 ]; then
        record_result "xiaping" "$skill_dir" "published" "uploaded new version through /api/upload" "https://xiaping.coze.site/skill/$existing_skill_id" "$existing_skill_id" "$version" "trial"
        return 0
      fi

      record_result "xiaping" "$skill_dir" "failed" "HTTP $upload_code from $base_url/api/upload"
      return 1
    fi
  fi

  if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    skill_id=$(python3 - <<'PY'
import json
try:
    with open('/tmp/skillup-xiaping-response.json', 'r', encoding='utf-8') as handle:
        payload = json.load(handle)
    print(payload.get('data', {}).get('skill', {}).get('id', ''))
except Exception:
    print('')
PY
)
    share_url=$(python3 - <<'PY'
import json
try:
    with open('/tmp/skillup-xiaping-response.json', 'r', encoding='utf-8') as handle:
        payload = json.load(handle)
    print(payload.get('data', {}).get('message', {}).get('share_url', ''))
except Exception:
    print('')
PY
)
    review_state=$(python3 - <<'PY'
import json
try:
    with open('/tmp/skillup-xiaping-response.json', 'r', encoding='utf-8') as handle:
        payload = json.load(handle)
    print(payload.get('data', {}).get('message', {}).get('status', {}).get('current', ''))
except Exception:
    print('')
PY
)
    record_result "xiaping" "$skill_dir" "published" "upload accepted by $base_url$upload_path" "$share_url" "$skill_id" "$version" "$review_state"
  else
    record_result "xiaping" "$skill_dir" "failed" "HTTP $http_code from $base_url$upload_path"
    return 1
  fi

  return 0
}
