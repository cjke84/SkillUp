---
name: SkillUp
description: 当你要把一个技能目录或技能仓库发布到 GitHub、虾评 Skill、OpenClaw 中文社区或 ClawHub，并希望优先使用环境变量和非浏览器自动化时使用
version: 0.1.4
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
        - gh
        - claw
        - clawhub
    primaryEnv: SKILLUP_GITHUB_TOKEN
    skillKey: SkillUp
    homepage: https://github.com/cjke84/SkillUp
---

# SkillUp

## Overview

`SkillUp` 通过一个统一的 shell 入口，对 skill 进行检查、打包和多平台发布。

它被设计成可在 Codex、OpenClaw 中文社区及其他能读取 `SKILL.md` 并执行 shell 命令的智能体环境中使用。

## When to Use

在这些场景下使用：

- 你要把一个 skill 发布到一个或多个平台
- 你要批量同步整个 skills 仓库
- 你希望尽量避免浏览器自动化
- 你希望优先从环境变量读取凭证，并允许配置文件回退

这些情况不适合使用：

- 任务只是修改 skill 内容，并不需要发布
- 目标平台只能通过浏览器手工完成，且无法用 CLI 或 HTTP 配置替代

## Inputs

统一入口：

```bash
./skills/SkillUp/scripts/publish.sh [publish|check|package] --source <path> [options]
```

常用参数：

- `--source <path>`: single skill directory or skill repository root
- `--platforms <csv>`: `github,xiaping,openclaw,clawhub`
- `--config <path>`: path to a local TOML-like config file
- `--artifact-dir <path>`: where packaged zip files are written
- `--result-file <path>`: where structured JSON results are written
- `--dry-run`: validate and package without external publishing
- `--fail-fast`: stop at the first failure
- `--continue-on-error`: keep going after failures
- `--retry <n>`: retry failed publishes

模式：

- `check`：检查 metadata、命令可用性和平台要求
- `package`：只校验并打包，不进行远程发布
- `publish`：校验、打包并执行发布
- `doctor`：检查本地发布环境是否齐全
- `status`：查看本地版本和远端平台状态
- `bump`：自动提升版本号

## Credential Priority

凭证优先级：

1. Environment variables
2. Config file values

默认支持的环境变量：

- `SKILLUP_GITHUB_TOKEN`
- `SKILLUP_XIAPING_API_KEY`
- `SKILLUP_OPENCLAW_TOKEN`
- `SKILLUP_CLAWHUB_TOKEN`
- `CLAWHUB_TOKEN`

## Expected Layout

单个 skill 目录至少应包含：

- `SKILL.md`

可选的每个 skill 元数据可写在：

- `manifest.toml`

如果是 skills 仓库模式，根目录下可以包含多个子 skill 目录，每个目录都有自己的 `SKILL.md`。

为了让 Codex 和 OpenClaw 中文社区都能直接发现并使用这个技能，建议安装到各自的默认技能目录之一：

- `~/.codex/skills/SkillUp`
- `~/.openclaw/skills/SkillUp`

平台开关：

- 在 `manifest.toml` 里设置 `[github].enabled = false` 之类的值，可以跳过某个平台
- 可以把 manifest 中的开关和 `--platforms <csv>` 组合使用，分别控制“允许的平台集合”和“实际启用的平台集合”

## Publish Flow

1. 从给定 source 路径发现 skill
2. 校验每个 skill 目录
3. 打包生成 zip 产物
4. 按要求尝试发布到各个平台
5. 输出简洁的成功、跳过和失败摘要
6. 把机器可读结果写入 `publish-result.json`

## Examples

以 dry-run 方式模拟发布单个 skill：

```bash
./skills/SkillUp/scripts/publish.sh \
  publish \
  --source ./skills/SkillUp \
  --platforms github,xiaping,openclaw,clawhub \
  --dry-run
```

只做校验：

```bash
./skills/SkillUp/scripts/publish.sh \
  check \
  --source ./skills/SkillUp \
  --result-file ./skills/SkillUp/.skillup-artifacts/check-result.json
```

使用配置文件发布整个 skills 仓库：

```bash
./skills/SkillUp/scripts/publish.sh \
  --source ./skills \
  --config ./skills/SkillUp/config.example.toml
```

## Notes

- GitHub 发布支持把产物同步到目标仓库，并通过 `gh` 创建或更新 release
- 虾评在有 `SKILLUP_XIAPING_API_KEY` 或配置文件凭证时走 HTTP API
- 虾评分类型会在可能的情况下通过实时分类 API 做校验
- ClawHub 优先使用官方 `clawhub` CLI，失败后再考虑 HTTP 回退
- OpenClaw 中文社区优先使用 `claw` 社区 CLI
- 如果你希望 OpenClaw 中文社区自动发现这个技能，请优先放在 `~/.openclaw/skills/SkillUp` 或当前 OpenClaw 工作区的 `skills/SkillUp`
- ClawHub 的服务端 trigger 异常会被单独分类，方便区分平台 bug 和本地打包问题
