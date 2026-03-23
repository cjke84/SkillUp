#!/bin/sh

publish_clawhub() {
  skill_dir=$1
  artifact_path=$2
  config_path=$3
  dry_run=$4

  token=$(env_or_config "SKILLUP_CLAWHUB_TOKEN" "$config_path" clawhub token "")
  if [ -z "$token" ]; then
    token=$(env_or_config "CLAWHUB_TOKEN" "$config_path" clawhub token "")
  fi
  base_url=$(config_get "$config_path" clawhub base_url "https://clawhub.ai")
  upload_path=$(config_get "$config_path" clawhub upload_path "/api/v1/skills")
  cli_bin=$(config_get "$config_path" clawhub cli_bin "clawhub")
  site_url=$(config_get "$config_path" clawhub site_url "https://clawhub.ai")
  registry_url=$(config_get "$config_path" clawhub registry_url "https://clawhub.ai")
  version=$(skill_version "$skill_dir")

  if [ "$dry_run" -eq 1 ]; then
    if command_exists "$cli_bin"; then
      record_result "clawhub" "$skill_dir" "dry-run" "would run $cli_bin publish $skill_dir --version $version"
    else
      record_result "clawhub" "$skill_dir" "dry-run" "would publish artifact $artifact_path"
    fi
    return
  fi

  if command_exists "$cli_bin"; then
    if [ -n "$token" ]; then
      CLAWHUB_TOKEN=$token
      export CLAWHUB_TOKEN
      "$cli_bin" login --token "$token" --site "$site_url" --registry "$registry_url" --no-input >/tmp/skillup-clawhub-login.log 2>&1 || true
    fi

    if "$cli_bin" publish "$skill_dir" --version "$version" --site "$site_url" --registry "$registry_url" --no-input >/tmp/skillup-clawhub-cli.log 2>&1; then
      record_result "clawhub" "$skill_dir" "published" "published through $cli_bin publish"
      return
    fi
  fi

  if [ -z "$base_url" ] || [ -z "$upload_path" ]; then
    if command_exists "$cli_bin"; then
      record_result "clawhub" "$skill_dir" "failed" "clawhub CLI publish failed and no endpoint is configured"
    else
      record_result "clawhub" "$skill_dir" "skipped" "endpoint not configured; artifact ready at $artifact_path"
    fi
    return
  fi

  if [ -n "$token" ]; then
    http_code=$(curl -sS -o /tmp/skillup-clawhub-response.json -w '%{http_code}' \
      -X POST "$base_url$upload_path" \
      -H "Authorization: Bearer $token" \
      -F "file=@$artifact_path")
  else
    http_code=$(curl -sS -o /tmp/skillup-clawhub-response.json -w '%{http_code}' \
      -X POST "$base_url$upload_path" \
      -F "file=@$artifact_path")
  fi

  if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    record_result "clawhub" "$skill_dir" "published" "upload accepted by $base_url$upload_path"
  else
    record_result "clawhub" "$skill_dir" "failed" "HTTP $http_code from $base_url$upload_path"
  fi
}
