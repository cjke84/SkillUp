# SkillUp

`SkillUp` is a cross-platform publishing skill for user-authored skills.

The current version in this repository focuses on:

- Standard `SKILL.md` compatibility for Codex and OpenClaw 中文社区-style agents
- Single-skill and multi-skill repository discovery
- `check`, `package`, and `publish` workflows
- Structured JSON result output
- Non-browser publishing flows
- Environment-variable-first credentials with config-file fallback
- Platform-specific validation before upload
- Manifest-based platform on/off switches

Publishing behavior currently prefers platform-native CLIs when available:

- `clawhub publish <path>` for ClawHub
- `claw skill publish` for OpenClaw 中文社区
- HTTP API upload for Xiaping Skill
- `git` repository sync for GitHub

GitHub publishing can also create or update a release when `github.repo` and `create_release = "true"` are configured in [config.example.toml](/Users/jingkechen/Documents/程序库/SkillUp/skills/SkillUp/config.example.toml).

Useful commands:

```bash
./skills/SkillUp/scripts/publish.sh check --source ./skills/SkillUp
./skills/SkillUp/scripts/publish.sh package --source ./skills/SkillUp
./skills/SkillUp/scripts/publish.sh publish --source ./skills/SkillUp --dry-run
```

Each run writes a machine-readable result file to `.skillup-artifacts/publish-result.json` by default.

Platform switches:

- Use `--platforms github,xiaping` to choose which platforms are considered in one run
- Use `enabled = false` inside a platform section in `manifest.toml` to explicitly skip that platform for a given skill

The implementation lives in [skills/SkillUp](/Users/jingkechen/Documents/程序库/SkillUp/skills/SkillUp).
