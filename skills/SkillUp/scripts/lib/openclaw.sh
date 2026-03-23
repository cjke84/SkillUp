#!/bin/sh

publish_openclaw() {
  skill_dir=$1
  artifact_path=$2
  config_path=$3
  dry_run=$4

  token=$(env_or_config "SKILLUP_OPENCLAW_TOKEN" "$config_path" openclaw token "")
  base_url=$(config_get "$config_path" openclaw base_url "")
  upload_path=$(config_get "$config_path" openclaw upload_path "")
  cli_bin=$(config_get "$config_path" openclaw cli_bin "claw")
  publish_args=$(config_get "$config_path" openclaw publish_args "")

  if [ "$dry_run" -eq 1 ]; then
    if command_exists "$cli_bin"; then
      record_result "openclaw" "$skill_dir" "dry-run" "would run $cli_bin skill publish for $skill_dir"
    else
      record_result "openclaw" "$skill_dir" "dry-run" "would publish artifact $artifact_path"
    fi
    return
  fi

  if command_exists "$cli_bin"; then
    if [ -n "$token" ]; then
      SKILLUP_OPENCLAW_TOKEN=$token
      export SKILLUP_OPENCLAW_TOKEN
    fi

    if [ -n "$publish_args" ]; then
      if (cd "$skill_dir" && "$cli_bin" skill publish $publish_args >/tmp/skillup-openclaw-cli.log 2>&1); then
        record_result "openclaw" "$skill_dir" "published" "published through $cli_bin skill publish"
        return
      fi
    else
      if (cd "$skill_dir" && "$cli_bin" skill publish >/tmp/skillup-openclaw-cli.log 2>&1); then
        record_result "openclaw" "$skill_dir" "published" "published through $cli_bin skill publish"
        return
      fi
    fi
  fi

  if [ -z "$base_url" ] || [ -z "$upload_path" ]; then
    if command_exists "$cli_bin"; then
      record_result "openclaw" "$skill_dir" "failed" "community CLI publish failed and no endpoint is configured"
    else
      record_result "openclaw" "$skill_dir" "skipped" "endpoint not configured; artifact ready at $artifact_path"
    fi
    return
  fi

  auth_header=""
  if [ -n "$token" ]; then
    auth_header="-H Authorization: Bearer $token"
  fi

  if [ -n "$auth_header" ]; then
    http_code=$(curl -sS -o /tmp/skillup-openclaw-response.json -w '%{http_code}' \
      -X POST "$base_url$upload_path" \
      -H "Authorization: Bearer $token" \
      -F "file=@$artifact_path")
  else
    http_code=$(curl -sS -o /tmp/skillup-openclaw-response.json -w '%{http_code}' \
      -X POST "$base_url$upload_path" \
      -F "file=@$artifact_path")
  fi

  if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    record_result "openclaw" "$skill_dir" "published" "upload accepted by $base_url$upload_path"
  else
    record_result "openclaw" "$skill_dir" "failed" "HTTP $http_code from $base_url$upload_path"
  fi
}
