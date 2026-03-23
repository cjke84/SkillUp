---
name: SkillUp
description: 当你要把一个技能目录或技能仓库发布到 GitHub、虾评 Skill、OpenClaw 中文社区或 ClawHub，并希望优先使用环境变量和非浏览器自动化时使用
version: 0.1.2
metadata:
  openclaw:
    requires:
      env:
        - SKILLUP_GITHUB_TOKEN
        - SKILLUP_XIAPING_API_KEY
        - SKILLUP_OPENCLAW_TOKEN
        - SKILLUP_CLAWHUB_TOKEN
      anyBins:
        - zip
        - python3
      bins:
        - curl
        - git
    primaryEnv: SKILLUP_GITHUB_TOKEN
    skillKey: SkillUp
    homepage: https://github.com/cjke84/SkillUp
---

# SkillUp

## Overview

`SkillUp` packages and publishes skills to multiple platforms through a single shell entrypoint.

It is designed to stay usable across Codex, OpenClaw 中文社区-compatible agents, and other agents that can read `SKILL.md` files and run shell commands.

## When to Use

Use this skill when:

- A user wants to publish a skill to one or more platforms
- A user wants to sync a whole skills repository in batch
- The workflow should avoid browser automation
- Credentials should come from environment variables first and a config file second

Do not use this skill when:

- The task is only to edit a skill's content without publishing
- The target platform requires browser-only manual steps that cannot be configured through CLI or HTTP

## Inputs

The entrypoint is:

```bash
./skills/SkillUp/scripts/publish.sh [publish|check|package] --source <path> [options]
```

Common options:

- `--source <path>`: single skill directory or skill repository root
- `--platforms <csv>`: `github,xiaping,openclaw,clawhub`
- `--config <path>`: path to a local TOML-like config file
- `--artifact-dir <path>`: where packaged zip files are written
- `--result-file <path>`: where structured JSON results are written
- `--dry-run`: validate and package without external publishing
- `--fail-fast`: stop at the first failure
- `--continue-on-error`: keep going after failures
- `--retry <n>`: retry failed publishes

Modes:

- `check`: validate metadata, command availability, and platform-specific requirements
- `package`: validate and produce artifacts without remote publishing
- `publish`: validate, package, and publish

## Credential Priority

Resolve credentials in this order:

1. Environment variables
2. Config file values

Supported variables in the first version:

- `SKILLUP_GITHUB_TOKEN`
- `SKILLUP_XIAPING_API_KEY`
- `SKILLUP_OPENCLAW_TOKEN`
- `SKILLUP_CLAWHUB_TOKEN`
- `CLAWHUB_TOKEN`

## Expected Layout

A single skill directory should contain:

- `SKILL.md`

Optional per-skill metadata may live in:

- `manifest.toml`

A repository source may contain multiple child directories, each with its own `SKILL.md`.

Platform switches:

- Set `[github].enabled = false` or the equivalent platform section in `manifest.toml` to skip publishing that platform
- Combine manifest switches with `--platforms <csv>` to control both the allowed set and the enabled set

## Publish Flow

1. Discover skills from the provided source path
2. Validate each discovered skill directory
3. Package each skill into a zip artifact
4. Attempt publishing for each requested platform
5. Print a concise summary of success, skipped items, and failures
6. Write machine-readable results to `publish-result.json`

## Examples

Publish a single skill in dry-run mode:

```bash
./skills/SkillUp/scripts/publish.sh \
  publish \
  --source ./skills/SkillUp \
  --platforms github,xiaping,openclaw,clawhub \
  --dry-run
```

Run validation only:

```bash
./skills/SkillUp/scripts/publish.sh \
  check \
  --source ./skills/SkillUp \
  --result-file ./skills/SkillUp/.skillup-artifacts/check-result.json
```

Publish a whole skills repository with a config file:

```bash
./skills/SkillUp/scripts/publish.sh \
  --source ./skills \
  --config ./skills/SkillUp/config.example.toml
```

## Notes

- GitHub publishing can copy packaged output into a target repository and commit it through `git`
- GitHub publishing can auto-create the configured repository and create/update releases through `gh`
- Xiaping publishing uses its HTTP API when `SKILLUP_XIAPING_API_KEY` or a config fallback is available
- Xiaping category values are validated against the live category API when possible
- ClawHub publishing prefers the official `clawhub` CLI, then falls back to a configured HTTP endpoint
- OpenClaw 中文社区 publishing prefers the `claw` community CLI, then falls back to a configured HTTP endpoint
- ClawHub server-side trigger failures are classified separately so agents can distinguish platform bugs from local packaging problems
