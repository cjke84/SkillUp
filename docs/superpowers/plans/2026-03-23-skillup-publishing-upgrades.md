# SkillUp Publishing Upgrades Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade `SkillUp` from a basic multi-platform publisher into a validated publishing workflow with structured results, richer adapter behavior, and better failure handling.

**Architecture:** Keep `publish.sh` as the single entrypoint, but split behavior into modes: `check`, `package`, and `publish`. The common library owns argument parsing, validation, retry/fail-fast policy, artifact packaging, and JSON result generation. Platform adapters focus on upload logic and emit structured metadata back to the common layer.

**Tech Stack:** Markdown, POSIX shell, `curl`, `git`, `gh`, `python3`, `zip`

---

### Task 1: Add failing shell tests

**Files:**
- Create: `tests/test_skillup.sh`

- [ ] **Step 1: Write a test for `check` mode output**
- [ ] **Step 2: Write a test for `publish-result.json` generation**
- [ ] **Step 3: Write a test for failure on missing `version` metadata**
- [ ] **Step 4: Run the test script and confirm it fails for missing features**

### Task 2: Refactor CLI modes and result model

**Files:**
- Modify: `skills/SkillUp/scripts/publish.sh`
- Modify: `skills/SkillUp/scripts/lib/common.sh`

- [ ] **Step 1: Add `check`, `package`, and `publish` modes**
- [ ] **Step 2: Add `--result-file`, `--fail-fast`, `--continue-on-error`, and `--retry` options**
- [ ] **Step 3: Emit structured JSON results**
- [ ] **Step 4: Re-run shell tests**

### Task 3: Strengthen validation and manifest support

**Files:**
- Modify: `skills/SkillUp/manifest.toml`
- Modify: `skills/SkillUp/templates/manifest.example.toml`
- Modify: `skills/SkillUp/scripts/lib/common.sh`

- [ ] **Step 1: Add platform-specific metadata expectations**
- [ ] **Step 2: Validate slug, version, artifacts, required files, and command availability**
- [ ] **Step 3: Add Xiaping category validation support**
- [ ] **Step 4: Re-run shell tests**

### Task 4: Upgrade platform adapters

**Files:**
- Modify: `skills/SkillUp/scripts/lib/github.sh`
- Modify: `skills/SkillUp/scripts/lib/xiaping.sh`
- Modify: `skills/SkillUp/scripts/lib/openclaw.sh`
- Modify: `skills/SkillUp/scripts/lib/clawhub.sh`

- [ ] **Step 1: Add GitHub repository auto-create and release automation improvements**
- [ ] **Step 2: Add OpenClaw 中文社区 result parsing**
- [ ] **Step 3: Add ClawHub known platform-bug classification**
- [ ] **Step 4: Re-run shell tests**

### Task 5: Verify end-to-end behavior

**Files:**
- Test: `tests/test_skillup.sh`
- Test: `skills/SkillUp/scripts/publish.sh`

- [ ] **Step 1: Run the shell test suite**
- [ ] **Step 2: Run `publish.sh check` against `skills/SkillUp`**
- [ ] **Step 3: Run `publish.sh publish --dry-run` and inspect `publish-result.json`**
- [ ] **Step 4: Summarize remaining external-platform limitations**
