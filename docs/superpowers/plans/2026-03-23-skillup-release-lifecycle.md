# SkillUp Release Lifecycle Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend `SkillUp` with release-lifecycle commands so the same CLI can bump versions, inspect environment readiness, query per-platform status, and detect version drift across platforms.

**Architecture:** Keep `publish.sh` as the single entrypoint and extend it with additional subcommands: `bump`, `status`, and `doctor`. Shared manifest/config parsing remains in `common.sh`, while each platform adapter adds optional read-only status functions. JSON result output remains the primary machine-readable interface.

**Tech Stack:** POSIX shell, `python3`, `git`, `gh`, `curl`

---

### Task 1: Extend shell tests

**Files:**
- Modify: `tests/test_skillup.sh`

- [ ] **Step 1: Add a failing test for `bump patch`**
- [ ] **Step 2: Add a failing test for `doctor` output**
- [ ] **Step 3: Add a failing test for `status --local-only`**
- [ ] **Step 4: Run the test script and confirm it fails for missing subcommands**

### Task 2: Add command parsing and version bumping

**Files:**
- Modify: `skills/SkillUp/scripts/lib/common.sh`
- Modify: `skills/SkillUp/scripts/publish.sh`

- [ ] **Step 1: Add `bump`, `status`, and `doctor` subcommands**
- [ ] **Step 2: Implement patch/minor/major version bumping across `SKILL.md` and `manifest.toml`**
- [ ] **Step 3: Emit JSON result output for non-publish commands**
- [ ] **Step 4: Re-run tests**

### Task 3: Add environment health checks

**Files:**
- Modify: `skills/SkillUp/scripts/lib/common.sh`

- [ ] **Step 1: Report required binaries and configured env vars**
- [ ] **Step 2: Report git/gh/claw/clawhub availability**
- [ ] **Step 3: Re-run tests**

### Task 4: Add platform status and version consistency checks

**Files:**
- Modify: `skills/SkillUp/scripts/lib/github.sh`
- Modify: `skills/SkillUp/scripts/lib/xiaping.sh`
- Modify: `skills/SkillUp/scripts/lib/openclaw.sh`
- Modify: `skills/SkillUp/scripts/lib/clawhub.sh`
- Modify: `skills/SkillUp/scripts/lib/common.sh`

- [ ] **Step 1: Add local status collection from manifest and repo state**
- [ ] **Step 2: Add remote status collection where safe and available**
- [ ] **Step 3: Flag version mismatches across configured platforms**
- [ ] **Step 4: Re-run tests**

### Task 5: Verify lifecycle commands

**Files:**
- Test: `tests/test_skillup.sh`
- Test: `skills/SkillUp/scripts/publish.sh`

- [ ] **Step 1: Run the test suite**
- [ ] **Step 2: Run `doctor`**
- [ ] **Step 3: Run `status` for `skills/SkillUp`**
- [ ] **Step 4: Run `bump patch` in a temporary test fixture**
