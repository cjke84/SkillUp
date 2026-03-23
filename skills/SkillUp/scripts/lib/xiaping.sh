#!/bin/sh

publish_xiaping() {
  skill_dir=$1
  artifact_path=$2
  config_path=$3
  dry_run=$4

  api_key=$(env_or_config "SKILLUP_XIAPING_API_KEY" "$config_path" xiaping api_key "")
  base_url=$(config_get "$config_path" xiaping base_url "https://xiaping.coze.site")
  upload_path=$(config_get "$config_path" xiaping upload_path "/api/skills")

  if [ "$dry_run" -eq 1 ]; then
    record_result "xiaping" "$skill_dir" "dry-run" "would upload $artifact_path to $base_url$upload_path"
    return
  fi

  if [ -z "$api_key" ]; then
    record_result "xiaping" "$skill_dir" "skipped" "missing API key"
    return
  fi

  http_code=$(curl -sS -o /tmp/skillup-xiaping-response.json -w '%{http_code}' \
    -X POST "$base_url$upload_path" \
    -H "Authorization: Bearer $api_key" \
    -F "file=@$artifact_path")

  if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    record_result "xiaping" "$skill_dir" "published" "upload accepted by $base_url$upload_path"
  else
    record_result "xiaping" "$skill_dir" "failed" "HTTP $http_code from $base_url$upload_path"
  fi
}
