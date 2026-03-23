# SkillUp

`SkillUp` 是一个面向自定义 skill 的跨平台发布工具。

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

当前版本重点提供这些能力：

- 兼容标准 `SKILL.md` 结构，适用于 Codex 与 OpenClaw 中文社区一类智能体
- 支持单个 skill 目录和多 skill 仓库
- 提供 `check`、`package`、`publish`、`bump`、`status`、`doctor` 工作流
- 输出结构化 JSON 结果
- 尽量使用非浏览器方式完成发布
- 凭证优先读取环境变量，配置文件作为回退
- 上传前做平台级校验
- 支持通过 manifest 为不同平台开启或关闭发布
- 支持发布生命周期管理和版本一致性检查

当前优先使用各平台原生能力：

- ClawHub：`clawhub publish <path>`
- OpenClaw 中文社区：`claw skill publish`
- 虾评 Skill：HTTP API
- GitHub：`git` + `gh`

如果在 [config.example.toml](/Users/jingkechen/Documents/程序库/SkillUp/skills/SkillUp/config.example.toml) 中配置了 `github.repo` 和 `create_release = "true"`，GitHub 还可以自动创建或更新 release。

常用命令：

```bash
./skills/SkillUp/scripts/publish.sh check --source ./skills/SkillUp
./skills/SkillUp/scripts/publish.sh package --source ./skills/SkillUp
./skills/SkillUp/scripts/publish.sh publish --source ./skills/SkillUp --dry-run
./skills/SkillUp/scripts/publish.sh doctor --source ./skills/SkillUp
./skills/SkillUp/scripts/publish.sh status --source ./skills/SkillUp --platforms github,xiaping,openclaw,clawhub
./skills/SkillUp/scripts/publish.sh bump patch --source ./skills/SkillUp
```

默认会把机器可读结果写到 `.skillup-artifacts/publish-result.json`。

平台开关：

- 用 `--platforms github,xiaping` 选择这次考虑哪些平台
- 在 `manifest.toml` 的平台区块里设置 `enabled = false` 可以让某个平台默认跳过

实现代码位于 [skills/SkillUp](/Users/jingkechen/Documents/程序库/SkillUp/skills/SkillUp)。
