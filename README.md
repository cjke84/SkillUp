# SkillUp

`SkillUp` is a cross-platform publishing skill for user-authored skills.

## 中文使用说明

`SkillUp` 用来把你自己写的 skill 从本地目录或 skill 仓库，一次性检查、打包并发布到多个平台。

目前重点支持这些平台：

- GitHub
- 虾评 Skill
- OpenClaw 中文社区
- ClawHub

常用流程：

1. 先检查 skill 是否满足发布要求
2. 再打包生成 zip 产物
3. 最后选择要发布的平台执行上传

最常用命令：

```bash
./skills/SkillUp/scripts/publish.sh check --source ./skills/SkillUp
./skills/SkillUp/scripts/publish.sh package --source ./skills/SkillUp
./skills/SkillUp/scripts/publish.sh publish --source ./skills/SkillUp --platforms github,xiaping --dry-run
```

如果你只想发部分平台，可以这样控制：

- 命令行用 `--platforms github,xiaping`
- `manifest.toml` 里给某个平台写 `enabled = false`

发布结果会默认写到：

```bash
./skills/SkillUp/.skillup-artifacts/publish-result.json
```

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
