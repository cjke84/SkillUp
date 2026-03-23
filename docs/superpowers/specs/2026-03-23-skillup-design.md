# SkillUp Design

## Goal

Create a reusable skill named `SkillUp` that helps Codex, OpenClaw-compatible agents, and similar assistants package and publish user-authored skills to multiple platforms without browser automation.

## Scope

`SkillUp` supports both of these source modes:

- A single skill directory
- A repository or root directory containing multiple skill directories

It targets these platforms:

- GitHub
- ClawHub
- Xiaping Skill
- OpenClaw Chinese community

## Design

The skill itself stays platform-neutral and tool-light:

- It documents a single entry command for agents to run
- It prefers shell commands, `git`, `gh`, and HTTP APIs
- It reads credentials from environment variables first and from a local config file second

Execution lives in scripts inside the skill package:

- `publish.sh` is the unified entrypoint
- `lib/common.sh` handles argument parsing, config lookup, packaging, and result reporting
- One adapter file per platform isolates publishing behavior

## Compatibility

To remain usable across Codex, OpenClaw, and other agent systems:

- The skill uses a standard `SKILL.md` with YAML frontmatter
- Required inputs are plain paths and flags
- Platform-specific behavior is implemented in shell scripts rather than proprietary tools

## Publishing Strategy

### GitHub

Support syncing packaged skills into a target repository through `git`, with optional release creation through `gh`.

### Xiaping Skill

Use its documented API-based upload flow when an API key is available.

### OpenClaw

Prefer the OpenClaw Chinese community CLI publish flow when the `claw` command is available. Otherwise, allow API or endpoint-based upload when configured. If no publish channel is available, keep the adapter dry-run compatible and leave a clear artifact/result record.

### ClawHub

Prefer the official `clawhub publish <path>` workflow with headless token login. Otherwise, allow API or endpoint-based upload when configured. If no publish channel is available, keep the adapter dry-run compatible and leave a clear artifact/result record.

## Output

Every run should:

- Discover source skills
- Validate the presence of `SKILL.md`
- Package each skill into a zip artifact
- Attempt per-platform publishing
- Produce a concise per-platform result summary

## Safety

- Default to explicit platform selection or all configured platforms
- Support `--dry-run`
- Continue through batch publishing even if one skill or one platform fails
