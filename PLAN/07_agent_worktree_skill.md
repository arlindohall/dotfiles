# Step 7: Extract agent-worktree skill

## Goal

Create a new `agent-worktree` skill that owns all worktree management scripts and
conventions. Move the existing worktree scripts from `plan-orchestrator` and
`plan-implementor` into this new skill, and update those skills to reference
`agent-worktree` instead of bundling their own scripts.

## Background

Currently, worktree management is spread across two skills:
- `plan-orchestrator/scripts/`: `setup-orch-worktree.sh`, `fetch-and-remove-step-worktree.sh`,
  `rebase-step.sh`, `remove-orch-worktree.sh`, `run-in-worktree-env.sh`, `run-touched-tests.sh`
- `plan-implementor/scripts/`: `setup-step-worktree.sh`

The naming convention is documented in `plan-orchestrator/SKILL.md`:

| Component | Path | Branch |
|-----------|------|--------|
| Orchestrator | `../PROJECT-orch-PLAN_SLUG/` | `orch-PLAN_SLUG` |
| Step NN | `../PROJECT-orch-PLAN_SLUG-stepNN/` | `orch-PLAN_SLUG-step-NN` |

This step:
1. Creates `~/.pi/agent/skills/agent-worktree/SKILL.md` documenting the conventions
2. Creates `~/.pi/agent/skills/agent-worktree/scripts/` and moves all scripts there
3. Updates `plan-orchestrator/SKILL.md` to reference `agent-worktree` for scripts
4. Updates `plan-implementor/SKILL.md` to reference `agent-worktree` for scripts
5. Updates `plan-reviewer/SKILL.md` to reference `agent-worktree` where applicable

The scripts themselves don't change — only their location and the references to them.

## Tests (write BEFORE implementation)

This step is a documentation and file-move refactor. There is no new code to unit test.
Verification is structural:

1. **All scripts exist in new location**: every `.sh` file from the source directories
   exists in `agent-worktree/scripts/`
2. **No scripts remain in old locations**: `plan-orchestrator/scripts/` and
   `plan-implementor/scripts/` are removed (or emptied)
3. **All script references in skill files are updated**: grep the updated SKILL.md files
   for the old `scripts/` paths — none should reference the old locations
4. **New SKILL.md is valid**: `agent-worktree/SKILL.md` has YAML frontmatter and
   documents all scripts
5. **Scripts are executable**: all `.sh` files have `+x` permission

## Files to create

### `~/.pi/agent/skills/agent-worktree/SKILL.md`

```markdown
---
name: agent-worktree
description: >
  Manages git worktrees for plan-based agent workflows. Provides scripts for creating
  orchestrator and step worktrees, fetching/removing them, rebasing steps, and running
  tests in worktree environments. Used by plan-orchestrator, plan-implementor,
  plan-reviewer, and agent-progress skills.
version: 0.1.0
---

# Agent Worktree

Centralized worktree management for multi-step plan execution. All scripts live in
`scripts/` relative to this skill directory.

## Naming Convention

| Component | Worktree Path | Branch Name |
|-----------|---------------|-------------|
| Orchestrator | `../PROJECT-orch-PLAN_HANDLE/` | `orch-PLAN_HANDLE` |
| Step NN | `../PROJECT-orch-PLAN_HANDLE-stepNN/` | `orch-PLAN_HANDLE-step-NN` |

`PLAN_HANDLE` is the `handle` field from PLAN.md's YAML frontmatter — a short,
lowercase, hyphenated slug (e.g., `add-docker-support`). This handle is the canonical
identifier shared across worktree names, branch names, task tracking, and memory tags.

**Branch name constraint:** Git does not allow a branch `orch-HANDLE` and
`orch-HANDLE/step-NN` to coexist. Always use a flat hyphen separator for step branches:
`orch-HANDLE-step-NN`.

## Scripts

All scripts are in the `scripts/` directory relative to this skill.

### setup-orch-worktree.sh

Create an orchestrator worktree and branch.

```
bash scripts/setup-orch-worktree.sh <PLAN_HANDLE> [PROJECT_NAME]
```

Outputs `REPO_ROOT`, `PROJECT_NAME`, `PLAN_HANDLE`, `ORCH_BRANCH`, `ORCH_WORKTREE` as
`KEY=VALUE` pairs.

### setup-step-worktree.sh

Create a step worktree branching from the orchestrator branch.

```
bash scripts/setup-step-worktree.sh <REPO_ROOT> <ORCH_WORKTREE> <ORCH_BRANCH> <PLAN_HANDLE> <STEP_ID>
```

Outputs `WORKTREE` and `BRANCH` as `KEY=VALUE` pairs.

### fetch-and-remove-step-worktree.sh

Fetch a step branch into the orchestrator repo and remove the step worktree.

```
bash scripts/fetch-and-remove-step-worktree.sh <ORCH_WORKTREE> <PLAN_HANDLE> <STEP_ID>
```

### rebase-step.sh

Rebase a step branch onto the orchestrator branch (linear history).

```
bash scripts/rebase-step.sh <ORCH_WORKTREE> <ORCH_BRANCH> <PLAN_HANDLE> <STEP_ID>
```

### remove-orch-worktree.sh

Clean up the orchestrator worktree and branch.

```
bash scripts/remove-orch-worktree.sh <REPO_ROOT> <ORCH_WORKTREE>
```

### run-in-worktree-env.sh

Run a command in a worktree with the original project's shadowenv/dev environment.

```
bash scripts/run-in-worktree-env.sh <ORIGINAL_PROJECT> <WORKTREE> -- <command...>
```

### run-touched-tests.sh

Run tests for files touched by the most recent commit.

```
bash scripts/run-touched-tests.sh [test-command]
```

## Usage by Other Skills

Skills that use worktrees should reference this skill and its scripts rather than
bundling their own. The scripts are invoked with `bash` using the absolute path
resolved from this skill's directory:

```bash
WORKTREE_SKILL_DIR="path/to/agent-worktree"
bash "${WORKTREE_SKILL_DIR}/scripts/setup-orch-worktree.sh" "${PLAN_HANDLE}"
```

The orchestrator, implementor, and reviewer skills all document which scripts they call
and when.
```

### `~/.pi/agent/skills/agent-worktree/scripts/`

Move (not copy) all of these files:

From `~/.pi/agent/skills/plan-orchestrator/scripts/`:
- `setup-orch-worktree.sh`
- `fetch-and-remove-step-worktree.sh`
- `rebase-step.sh`
- `remove-orch-worktree.sh`
- `run-in-worktree-env.sh`
- `run-touched-tests.sh`

From `~/.pi/agent/skills/plan-implementor/scripts/`:
- `setup-step-worktree.sh`

**Important**: In each moved script, update the variable name `PLAN_SLUG` → `PLAN_HANDLE`
in comments and usage strings for consistency with the new naming. The actual variable
values are the same — this is a rename for documentation clarity. The script logic does
not change.

## Files to edit

### `~/.pi/agent/skills/plan-orchestrator/SKILL.md`

Replace all inline script references (e.g., `scripts/setup-orch-worktree.sh`) with
references to the `agent-worktree` skill. Specifically:

1. Remove the `scripts/` directory references throughout
2. Add a dependency note at the top:

```markdown
## Dependencies

This skill depends on:
- **agent-worktree** — for worktree creation, cleanup, and test running scripts
- **agent-progress** — for task progress tracking (see agent-progress skill)
```

3. Replace each `scripts/setup-orch-worktree.sh` call with a note to use the
   agent-worktree skill's script, e.g.:

```markdown
Use the agent-worktree skill to create the orchestrator worktree:

```bash
# Resolve the agent-worktree skill directory, then:
bash "${WORKTREE_SKILL_DIR}/scripts/setup-orch-worktree.sh" "${PLAN_HANDLE}" [project-name]
```
```

4. Replace all occurrences of `PLAN_SLUG` with `PLAN_HANDLE`

5. Remove the `scripts/` directory from `plan-orchestrator` after confirming all scripts
   are moved

### `~/.pi/agent/skills/plan-implementor/SKILL.md`

1. Replace the `scripts/setup-step-worktree.sh` reference with agent-worktree reference
2. Replace all occurrences of `PLAN_SLUG` with `PLAN_HANDLE`
3. Remove the `scripts/` directory from `plan-implementor`

### `~/.pi/agent/skills/plan-reviewer/SKILL.md`

1. Replace any references to worktree scripts with agent-worktree references (the
   reviewer doesn't create worktrees but may reference the naming convention)
2. Replace `PLAN_SLUG` with `PLAN_HANDLE` where it appears

## Acceptance criteria

- `~/.pi/agent/skills/agent-worktree/SKILL.md` exists with valid YAML frontmatter
- All 7 scripts exist in `~/.pi/agent/skills/agent-worktree/scripts/` and are executable
- `~/.pi/agent/skills/plan-orchestrator/scripts/` directory is removed
- `~/.pi/agent/skills/plan-implementor/scripts/` directory is removed
- No SKILL.md in plan-orchestrator, plan-implementor, or plan-reviewer references a local `scripts/` path
- All references to `PLAN_SLUG` in the updated skills are replaced with `PLAN_HANDLE`
- The agent-worktree SKILL.md documents all 7 scripts with usage examples
- The Worktree Naming Convention table uses `PLAN_HANDLE` (not `PLAN_SLUG`)

## Dependencies

None — this is a pure refactoring step with no code dependencies. Can run in parallel
with steps 0–6.
