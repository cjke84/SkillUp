---
name: SkillUp
description: Use when publishing one skill or a repository of skills to GitHub, Xiaping Skill, OpenClaw 中文社区, or ClawHub with environment-first credentials and non-browser automation
version: 0.1.0
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
./skills/SkillUp/scripts/publish.sh --source <path> [options]
```

Common options:

- `--source <path>`: single skill directory or skill repository root
- `--platforms <csv>`: `github,xiaping,openclaw,clawhub`
- `--config <path>`: path to a local TOML-like config file
- `--artifact-dir <path>`: where packaged zip files are written
- `--dry-run`: validate and package without external publishing

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

## Publish Flow

1. Discover skills from the provided source path
2. Validate each discovered skill directory
3. Package each skill into a zip artifact
4. Attempt publishing for each requested platform
5. Print a concise summary of success, skipped items, and failures

## Examples

Publish a single skill in dry-run mode:

```bash
./skills/SkillUp/scripts/publish.sh \
  --source ./skills/SkillUp \
  --platforms github,xiaping,openclaw,clawhub \
  --dry-run
```

Publish a whole skills repository with a config file:

```bash
./skills/SkillUp/scripts/publish.sh \
  --source ./skills \
  --config ./skills/SkillUp/config.example.toml
```

## Notes

- GitHub publishing can copy packaged output into a target repository and commit it through `git`
- Xiaping publishing uses its HTTP API when `SKILLUP_XIAPING_API_KEY` or a config fallback is available
- ClawHub publishing prefers the official `clawhub` CLI, then falls back to a configured HTTP endpoint
- OpenClaw 中文社区 publishing prefers the `claw` community CLI, then falls back to a configured HTTP endpoint
