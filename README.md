# SkillUp

`SkillUp` is a cross-platform publishing skill for user-authored skills.

The first version in this repository focuses on:

- Standard `SKILL.md` compatibility for Codex and OpenClaw 中文社区-style agents
- Single-skill and multi-skill repository discovery
- Non-browser publishing flows
- Environment-variable-first credentials with config-file fallback

Publishing behavior currently prefers platform-native CLIs when available:

- `clawhub publish <path>` for ClawHub
- `claw skill publish` for OpenClaw 中文社区
- HTTP API upload for Xiaping Skill
- `git` repository sync for GitHub

GitHub publishing can also create or update a release when `github.repo` and `create_release = "true"` are configured in [config.example.toml](/Users/jingkechen/Documents/程序库/SkillUp/skills/SkillUp/config.example.toml).

The implementation lives in [skills/SkillUp](/Users/jingkechen/Documents/程序库/SkillUp/skills/SkillUp).
