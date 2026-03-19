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

```bash
bash scripts/setup-orch-worktree.sh <PLAN_HANDLE> [PROJECT_NAME]
```

Outputs `REPO_ROOT`, `PROJECT_NAME`, `PLAN_HANDLE`, `ORCH_BRANCH`, `ORCH_WORKTREE` as
`KEY=VALUE` pairs.

### setup-step-worktree.sh

Create a step worktree branching from the orchestrator branch.

```bash
bash scripts/setup-step-worktree.sh <REPO_ROOT> <ORCH_WORKTREE> <ORCH_BRANCH> <PLAN_HANDLE> <STEP_ID>
```

Outputs `WORKTREE` and `BRANCH` as `KEY=VALUE` pairs.

### fetch-and-remove-step-worktree.sh

Fetch a step branch into the orchestrator repo and remove the step worktree.

```bash
bash scripts/fetch-and-remove-step-worktree.sh <ORCH_WORKTREE> <PLAN_HANDLE> <STEP_ID>
```

### rebase-step.sh

Rebase a step branch onto the orchestrator branch (linear history).

```bash
bash scripts/rebase-step.sh <ORCH_WORKTREE> <ORCH_BRANCH> <PLAN_HANDLE> <STEP_ID>
```

### remove-orch-worktree.sh

Clean up the orchestrator worktree and branch.

```bash
bash scripts/remove-orch-worktree.sh <REPO_ROOT> <ORCH_WORKTREE>
```

### run-in-worktree-env.sh

Run a command in a worktree with the original project's shadowenv/dev environment.

```bash
bash scripts/run-in-worktree-env.sh <ORIGINAL_PROJECT> <WORKTREE> -- <command...>
```

### run-touched-tests.sh

Run tests for files touched by the most recent commit.

```bash
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
