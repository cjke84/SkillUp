#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

assert_contains() {
  file_path=$1
  expected=$2
  if ! grep -F "$expected" "$file_path" >/dev/null 2>&1; then
    echo "Expected '$expected' in $file_path" >&2
    exit 1
  fi
}

assert_not_contains() {
  file_path=$1
  unexpected=$2
  if grep -F "$unexpected" "$file_path" >/dev/null 2>&1; then
    echo "Did not expect '$unexpected' in $file_path" >&2
    exit 1
  fi
}

make_skill() {
  skill_dir=$1
  version_line=$2
  mkdir -p "$skill_dir"
  cat > "$skill_dir/SKILL.md" <<EOF
---
name: test-skill
description: test skill
$version_line
---

# test
EOF
}

make_manifest() {
  skill_dir=$1
  github_enabled=$2
  xiaping_enabled=$3
  cat > "$skill_dir/manifest.toml" <<EOF
name = "test-skill"
slug = "test-skill"
version = "1.2.3"
description = "测试发布技能"
category = "开发辅助"

[github]
enabled = $github_enabled

[xiaping]
enabled = $xiaping_enabled
title_zh = "测试技能中文名"
description_zh = "这是给虾评使用的中文介绍"
trigger = "[\"测试技能\"]"
category = "[\"开发辅助\"]"
tags = "[\"测试\"]"

[openclaw]
enabled = true
title_zh = "OpenClaw 中文标题"
description_zh = "这是给 OpenClaw 中文社区使用的中文介绍"

[clawhub]
enabled = true
title_en = "SkillUp English Title"
description_en = "English description for ClawHub."
EOF
}

TEST_SKILL="$TMP_DIR/skills/test-skill"
make_skill "$TEST_SKILL" "version: 1.2.3"
make_manifest "$TEST_SKILL" true true

RESULT_JSON="$TMP_DIR/result.json"
CHECK_LOG="$TMP_DIR/check.log"

"$ROOT_DIR/skills/SkillUp/scripts/publish.sh" check \
  --source "$TEST_SKILL" \
  --platforms github \
  --result-file "$RESULT_JSON" \
  >"$CHECK_LOG" 2>&1

assert_contains "$CHECK_LOG" "[check]"
assert_contains "$RESULT_JSON" "\"platform\": \"check\""
assert_contains "$RESULT_JSON" "\"status\": \"validated\""

PUBLISH_LOG="$TMP_DIR/publish.log"
"$ROOT_DIR/skills/SkillUp/scripts/publish.sh" publish \
  --source "$TEST_SKILL" \
  --platforms github \
  --dry-run \
  --result-file "$RESULT_JSON" \
  >"$PUBLISH_LOG" 2>&1

assert_contains "$PUBLISH_LOG" "[github]"
assert_contains "$RESULT_JSON" "\"platform\": \"github\""
assert_contains "$RESULT_JSON" "\"status\": \"dry-run\""

SWITCHED_SKILL="$TMP_DIR/skills/switched-skill"
make_skill "$SWITCHED_SKILL" "version: 1.2.3"
make_manifest "$SWITCHED_SKILL" false true
SWITCH_LOG="$TMP_DIR/switch.log"

"$ROOT_DIR/skills/SkillUp/scripts/publish.sh" publish \
  --source "$SWITCHED_SKILL" \
  --platforms github,xiaping \
  --dry-run \
  --result-file "$RESULT_JSON" \
  >"$SWITCH_LOG" 2>&1

assert_contains "$SWITCH_LOG" "[github]"
assert_contains "$SWITCH_LOG" "platform disabled in manifest"
assert_contains "$SWITCH_LOG" "[xiaping]"

BROKEN_SKILL="$TMP_DIR/skills/broken-skill"
make_skill "$BROKEN_SKILL" ""
BROKEN_LOG="$TMP_DIR/broken.log"

if "$ROOT_DIR/skills/SkillUp/scripts/publish.sh" check --source "$BROKEN_SKILL" >"$BROKEN_LOG" 2>&1; then
  echo "Expected check mode to fail for missing version" >&2
  exit 1
fi

assert_contains "$BROKEN_LOG" "Missing version metadata"

BUMP_SKILL="$TMP_DIR/skills/bump-skill"
make_skill "$BUMP_SKILL" "version: 1.2.3"
make_manifest "$BUMP_SKILL" true true
BUMP_LOG="$TMP_DIR/bump.log"

"$ROOT_DIR/skills/SkillUp/scripts/publish.sh" bump patch \
  --source "$BUMP_SKILL" \
  --result-file "$RESULT_JSON" \
  >"$BUMP_LOG" 2>&1

assert_contains "$BUMP_LOG" "1.2.4"
assert_contains "$BUMP_SKILL/SKILL.md" "version: 1.2.4"
assert_contains "$BUMP_SKILL/manifest.toml" "version = \"1.2.4\""

DOCTOR_LOG="$TMP_DIR/doctor.log"
"$ROOT_DIR/skills/SkillUp/scripts/publish.sh" doctor \
  --source "$TEST_SKILL" \
  --result-file "$RESULT_JSON" \
  >"$DOCTOR_LOG" 2>&1

assert_contains "$DOCTOR_LOG" "[doctor]"
assert_contains "$RESULT_JSON" "\"platform\": \"doctor\""

STATUS_LOG="$TMP_DIR/status.log"
"$ROOT_DIR/skills/SkillUp/scripts/publish.sh" status \
  --source "$TEST_SKILL" \
  --platforms github,xiaping \
  --result-file "$RESULT_JSON" \
  >"$STATUS_LOG" 2>&1

assert_contains "$STATUS_LOG" "[status]"
assert_contains "$RESULT_JSON" "\"platform\": \"status\""
assert_not_contains "$STATUS_LOG" "Unknown argument"

SUMMARY_LOG="$TMP_DIR/summary.log"
 /bin/sh -c '. "'"$ROOT_DIR"'/skills/SkillUp/scripts/lib/common.sh"; record_result clawhub /tmp/demo status-review "ClawHub security scan pending" "" "" "1.2.3" "security_scan_pending"; print_status_summary /tmp/demo 1.2.3' \
  >"$SUMMARY_LOG" 2>&1

assert_contains "$SUMMARY_LOG" "ClawHub扫描中"

XIAPING_SUMMARY_LOG="$TMP_DIR/xiaping-summary.log"
/bin/sh -c '. "'"$ROOT_DIR"'/skills/SkillUp/scripts/lib/common.sh"; record_result xiaping /tmp/xiaping-demo platform-version-adjusted "Xiaping accepted publish with platform-adjusted version 0.1.6" "https://xiaping.coze.site/skill/demo" "demo" "0.1.6" "trial"; print_status_summary /tmp/xiaping-demo 0.1.5' \
  >"$XIAPING_SUMMARY_LOG" 2>&1

assert_contains "$XIAPING_SUMMARY_LOG" "虾评已同步"
assert_not_contains "$XIAPING_SUMMARY_LOG" "虾评未同步"

LOCALIZED_LOG="$TMP_DIR/localized.log"
/bin/sh -c '. "'"$ROOT_DIR"'/skills/SkillUp/scripts/lib/common.sh"; \
  localized_xiaping=$(prepare_platform_skill_dir "'"$TEST_SKILL"'" xiaping); \
  localized_openclaw=$(prepare_platform_skill_dir "'"$TEST_SKILL"'" openclaw); \
  localized_clawhub=$(prepare_platform_skill_dir "'"$TEST_SKILL"'" clawhub); \
  printf "xiaping_name=%s\n" "$(frontmatter_get "$localized_xiaping" name)"; \
  printf "xiaping_description=%s\n" "$(frontmatter_get "$localized_xiaping" description)"; \
  printf "openclaw_name=%s\n" "$(frontmatter_get "$localized_openclaw" name)"; \
  printf "openclaw_description=%s\n" "$(frontmatter_get "$localized_openclaw" description)"; \
  printf "clawhub_name=%s\n" "$(frontmatter_get "$localized_clawhub" name)"; \
  printf "clawhub_description=%s\n" "$(frontmatter_get "$localized_clawhub" description)"; \
  rm -rf "$(dirname "$localized_xiaping")" "$(dirname "$localized_openclaw")" "$(dirname "$localized_clawhub")"' \
  >"$LOCALIZED_LOG" 2>&1

assert_contains "$LOCALIZED_LOG" "xiaping_name=测试技能中文名"
assert_contains "$LOCALIZED_LOG" "xiaping_description=这是给虾评使用的中文介绍"
assert_contains "$LOCALIZED_LOG" "openclaw_name=OpenClaw 中文标题"
assert_contains "$LOCALIZED_LOG" "openclaw_description=这是给 OpenClaw 中文社区使用的中文介绍"
assert_contains "$LOCALIZED_LOG" "clawhub_name=SkillUp English Title"
assert_contains "$LOCALIZED_LOG" "clawhub_description=English description for ClawHub."

CLAWHUB_STATUS_LOG="$TMP_DIR/clawhub-status.log"
/bin/sh -c '. "'"$ROOT_DIR"'/skills/SkillUp/scripts/lib/common.sh"; . "'"$ROOT_DIR"'/skills/SkillUp/scripts/lib/clawhub.sh"; cat > /tmp/skillup-clawhub-status.json <<'\''EOF'\'' 
{"skill":{"summary":"English description for ClawHub."},"latestVersion":{"version":"1.2.3"}}
EOF
if clawhub_remote_version_from_file /tmp/skillup-clawhub-status.json; then
  printf "remote_version=%s\n" "$(clawhub_remote_version_from_file /tmp/skillup-clawhub-status.json)"
else
  printf "remote_version=\n"
fi' >"$CLAWHUB_STATUS_LOG" 2>&1

assert_contains "$CLAWHUB_STATUS_LOG" "remote_version=1.2.3"

OPENCLAW_SUMMARY_LOG="$TMP_DIR/openclaw-summary.log"
/bin/sh -c '. "'"$ROOT_DIR"'/skills/SkillUp/scripts/lib/common.sh"; record_result openclaw /tmp/openclaw-demo status-review "OpenClaw 中文社区 CLI returned unparsable skill list" "" "demo" "1.2.3" "cli_parse_error"; print_status_summary /tmp/openclaw-demo 1.2.3' \
  >"$OPENCLAW_SUMMARY_LOG" 2>&1

assert_contains "$OPENCLAW_SUMMARY_LOG" "OpenClaw 中文社区待确认"

assert_contains "$ROOT_DIR/skills/SkillUp/SKILL.md" "        - gh"
assert_contains "$ROOT_DIR/skills/SkillUp/SKILL.md" "        - claw"
assert_contains "$ROOT_DIR/skills/SkillUp/SKILL.md" "        - clawhub"
assert_contains "$ROOT_DIR/README.md" "~/.openclaw/skills/SkillUp"

echo "skillup tests passed"
