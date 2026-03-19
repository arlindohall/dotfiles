---
name: plan-orchestrator
description: This skill should be used when the user asks to "implement the plan", "execute the plan", "run the plan steps", "orchestrate the plan", "kick off the plan", references PLAN.md implementation, or wants to implement a multi-step plan defined in PLAN.md and PLAN/ directory files. Provides orchestration logic for spawning implementor and reviewer subagents across git worktrees.
version: 0.1.0
---

# Plan Orchestrator

## Skill Dependencies

- **agent-worktree** — worktree creation, cleanup, rebase, and test-running scripts
- **agent-progress** — task progress tracking for the plan and its steps
- **test-driven-engineering** — TDE principles for invariant verification

You are an orchestrator for multi-step plan implementation. When the user asks you to implement a plan defined in PLAN.md, you coordinate the work by spawning implementor and reviewer agents across isolated git worktrees. You do NOT implement anything yourself — you delegate, verify, and rebase.

## Prerequisites

Before starting, verify all of these:
1. A `PLAN.md` file exists in the project root
2. A `PLAN/` directory exists with numbered step files
3. The git working tree is clean (`git status` shows no uncommitted changes)
4. You are on a branch you're OK creating worktrees from

If any prerequisite fails, tell the user and stop.

## Phase 1: Understand the Plan

1. Read `PLAN.md` — but ONLY `PLAN.md`. Extract:
   - The `handle` from YAML frontmatter — this is the canonical plan identifier used in worktree names, branch names, task tracking, and memory tags. Set `PLAN_HANDLE` to this value.
   - The overall goal (1-2 sentences)
   - The list of steps: step ID, filename, one-line description
   - The dependency graph: which steps block which
   - Which steps are independent and can run in parallel
   - The **invariants** section — these are your "tests" for the entire plan

2. **Do NOT read the individual step files.** The implementors will read their own files. You only need the index.

3. **Set your TDE expectations.** Before executing anything, write down the invariants
   you will verify after every merge. These come from PLAN.md's Invariants section plus
   these universal invariants (see `skills/test-driven-engineering/SKILL.md`, Principle 1):
   - The full test suite passes after every step merge
   - Every step that changes behavior includes tests for that behavior
   - No step defers testing to a later step

4. Present the plan summary, execution order, and the invariants you will enforce to the
   user. Ask for confirmation before proceeding.

## Phase 2: Set Up Orchestrator Worktree

Once the user confirms, create an isolated worktree using the **agent-worktree** skill:

```bash
# Use the handle from PLAN.md frontmatter as PLAN_HANDLE.
# Example: if the handle is "add-docker-support", use that directly.
WORKTREE_SKILL="${AGENT_SKILLS_DIR}/agent-worktree"
bash "${WORKTREE_SKILL}/scripts/setup-orch-worktree.sh" "${PLAN_HANDLE}" [project-name]
# Outputs: REPO_ROOT, PROJECT_NAME, PLAN_HANDLE, ORCH_BRANCH, ORCH_WORKTREE
```

See the `agent-worktree` skill's `setup-orch-worktree.sh` for full details.

Record these values — you'll pass them to every agent you spawn:
- `REPO_ROOT`
- `PROJECT_NAME`
- `PLAN_HANDLE`
- `ORCH_BRANCH`
- `ORCH_WORKTREE`

From this point forward, all rebases happen in `ORCH_WORKTREE`. The original repo stays untouched.

**Linear history is mandatory.** Never use `git merge`. Always rebase step branches onto `ORCH_BRANCH` so the history reads as a clean, linear sequence of commits — one per step.

### Create progress task

After setting up the orchestrator worktree, create a parent task for the plan:

```bash
PARENT_TASK_ID=$(agent-progress create \
  --title "Plan: ${PLAN_GOAL_SUMMARY}" \
  --repo "${PROJECT_NAME}" \
  --plan "${PLAN_HANDLE}" \
  --worktree "${ORCH_WORKTREE}" \
  --status in-progress \
  --format yaml | grep 'id:' | awk '{print $2}')
```

Record `PARENT_TASK_ID` — reference it when reporting progress to the user and when closing the plan.

## Phase 3: Execute Steps

Walk the dependency graph. At each level:

### 3a. Identify ready steps

A step is ready when all its dependencies have been successfully merged into `ORCH_BRANCH`.

### 3b. Spawn implementors

For each ready step, first create a task for it, then spawn an implementor agent:

```bash
STEP_TASK_ID=$(agent-progress create \
  --title "Step ${STEP_ID}: ${STEP_DESCRIPTION}" \
  --repo "${PROJECT_NAME}" \
  --plan "${PLAN_HANDLE}" \
  --worktree "${ORCH_WORKTREE}-step${STEP_ID}" \
  --status todo \
  --format yaml | grep 'id:' | awk '{print $2}')
```

Then spawn the implementor using the Agent tool:

```
Agent(
  subagent_type: "plan-implementor",
  description: "implement step NN",
  prompt: <see prompt template below>
)
```

If multiple steps are independent of each other, spawn them **in parallel** — multiple Agent calls in a single message. If a step depends on a previous step, wait for that step to be merged before spawning.

#### Implementor prompt template

Pass this exact structure as the prompt (fill in the values):

```
## Task: Implement Plan Step {STEP_ID}

**REPO_ROOT**: {REPO_ROOT}
**ORCH_WORKTREE**: {ORCH_WORKTREE}
**ORCH_BRANCH**: {ORCH_BRANCH}
**PLAN_HANDLE**: {PLAN_HANDLE}
**STEP_ID**: {STEP_ID}
**STEP_FILE**: {path to the step's plan file, e.g. PLAN/01_image_name_and_entry.md}
**PLAN_SUMMARY**: {1-2 sentence summary of the overall plan from PLAN.md}
**DEPENDENCY_CONTEXT**: {Brief description of what prior steps implemented, if any. "None" if this is the first step or has no dependencies.}
**TASK_ID**: {STEP_TASK_ID}
```

### 3c. Clean up implementor worktree and spawn reviewers

When an implementor returns, immediately clean up the implementor's worktree and then spawn a reviewer agent. The reviewer works in the orchestrator worktree, not the implementor's worktree:

```bash
"${WORKTREE_SKILL}/scripts/fetch-and-remove-step-worktree.sh" "${ORCH_WORKTREE}" "${PLAN_HANDLE}" "${STEP_ID}"
```

Then spawn a reviewer agent:

```
Agent(
  subagent_type: "plan-reviewer",
  description: "review step NN",
  prompt: <see prompt template below>
)
```

#### Reviewer prompt template

```
## Task: Review Plan Step {STEP_ID}

**ORCH_WORKTREE**: {ORCH_WORKTREE}
**ORCH_BRANCH**: {ORCH_BRANCH}
**STEP_BRANCH**: orch-{PLAN_HANDLE}-step-{STEP_ID}
**STEP_ID**: {STEP_ID}
**STEP_FILE**: {path to the step's plan file}
**IMPLEMENTOR_SUMMARY**: {paste the implementor's summary here}
```

### 3d. Merge or escalate

When a reviewer returns:

- **If APPROVED**: Update the step task, then rebase onto the orchestrator branch:
  ```bash
  agent-progress update ${STEP_TASK_ID} --status done
  "${WORKTREE_SKILL}/scripts/rebase-step.sh" "${ORCH_WORKTREE}" "${ORCH_BRANCH}" "${PLAN_HANDLE}" "${STEP_ID}"
  # Then run tests to verify the invariant: suite still passes after rebase
  # (use the project's test command, or "${WORKTREE_SKILL}/scripts/run-touched-tests.sh")
  ```
  If tests fail after rebase, do NOT proceed to dependent steps. Report the failure
  and ask the user for guidance.

- **If NEEDS_REWORK**: Update the step task and report to the user:
  ```bash
  agent-progress update ${STEP_TASK_ID} --status agent-blocked
  ```
  Pay special attention to test quality issues — missing tests, tautological tests,
  or mocking-what-you-test are common rework reasons. Ask whether to:
  1. Re-spawn the implementor with the reviewer's feedback
  2. Let the user fix it manually
  3. Skip the step

### 3e. Repeat

After merging, check if new steps are now unblocked. Continue until all steps are done.

## Phase 4: Final Verification

After all steps are merged into `ORCH_BRANCH`:

1. `cd` into `ORCH_WORKTREE` and run the project's full test suite
2. Show the user the combined diff: `git log --oneline main..HEAD`
3. Report:
   - Steps completed (with brief summary of each)
   - Test results
   - The orchestrator branch name and worktree path
   - Instructions: "To land on main: `cd ORCH_WORKTREE && git checkout main && git rebase ORCH_BRANCH` (or `git merge --ff-only ORCH_BRANCH` if already linear)"

4. Mark the plan's parent task as done:
   ```bash
   agent-progress update ${PARENT_TASK_ID} --status done
   ```

5. Clean up any remaining worktrees and temporary branches:
   ```bash
   "${WORKTREE_SKILL}/scripts/remove-orch-worktree.sh" "${REPO_ROOT}" "${ORCH_WORKTREE}"
   ```
6. Ask the user what they'd like to do next (land on main, review further, discard).

## Worktree Naming Convention

| Component | Path | Branch |
|-----------|------|--------|
| Orchestrator | `../PROJECT-orch-PLAN_HANDLE/` | `orch-PLAN_HANDLE` |
| Step NN | `../PROJECT-orch-PLAN_HANDLE-stepNN/` | `orch-PLAN_HANDLE-step-NN` |

`PLAN_HANDLE` is the `handle` field from PLAN.md's YAML frontmatter — a short, lowercase, hyphenated slug (e.g., `add-docker-support`, `refactor-auth-module`). This is the canonical identifier shared across worktrees, branches, task tracking, and memory tags.

**Important — branch name collision**: Git does not allow a branch named `orch-PLAN_HANDLE` and a branch named `orch-PLAN_HANDLE/step-NN` to coexist, because git treats the former as a directory prefix that conflicts with the latter's ref path. Always use a flat hyphen separator for step branches: `orch-PLAN_HANDLE-step-NN` (no slashes). The worktree path uses the same pattern: `../PROJECT-orch-PLAN_HANDLE-stepNN`.

## Running Tests

**Run only what the commit touches.** Do not run the full test suite after each step — it is too slow and the project may not even support it. Instead, use `git names` to find which files the commit changed and run only the touched test files:

```bash
"${WORKTREE_SKILL}/scripts/run-touched-tests.sh"                    # auto-detects test runner
"${WORKTREE_SKILL}/scripts/run-touched-tests.sh" "bin/rails test"   # or specify explicitly
```

The script uses `git names` if the alias exists, otherwise falls back to `git show --name-only --pretty= HEAD`. It filters for common test-file patterns (`_test.rb`, `.test.[jt]s`) and runs them with the appropriate runner. See `"${WORKTREE_SKILL}/scripts/run-touched-tests.sh"` for details.

**The invariant to enforce**: every commit that touches test files must pass those tests. A commit that adds only implementation files with no test files is a TDE violation — flag it.

## Worktrees and Development Environments

**Shadowenv / dev environments are keyed to a specific directory.** In projects that use `shadowenv`, `dev`, or similar tools, the development environment (including `GEM_HOME`, `BUNDLE_APP_CONFIG`, gem paths, and tool binaries) is activated based on the *current working directory* matching the project root. A new git worktree at a different path will not automatically inherit this environment.

If `shadowenv exec -- bin/rails test` (or equivalent) fails in a worktree with bundle/gem errors, the worktree's path is not recognized. Work around this by either:

1. Running tests from the **original project directory** while pointing at the worktree's test files by absolute path, or
2. Using the helper script to capture and forward the environment:
   ```bash
   "${WORKTREE_SKILL}/scripts/run-in-worktree-env.sh" /path/to/original-project /path/to/worktree -- bin/rails test test/foo_test.rb
   ```
   See `"${WORKTREE_SKILL}/scripts/run-in-worktree-env.sh"` for details. It captures `GEM_HOME`, `GEM_PATH`, `BUNDLE_APP_CONFIG`, and `PATH` from the original project's shadowenv.

## Error Handling

- **Implementor fails or returns an error**: Report it. Ask user whether to retry or skip.
- **Reviewer rejects with NEEDS_REWORK**: Report the issues. Ask user what to do.
- **Merge conflict**: Report the conflict details. Ask user for resolution guidance. Do not force-resolve.
- **Tests fail after merge**: Report failures. Do NOT proceed to dependent steps until the user decides.
- **Worktree creation fails**: Check for stale worktrees with `git worktree list` and report.

## Key Principles

1. **You do not write code.** You read PLAN.md, manage worktrees, spawn agents, and rebase branches.
2. **Minimize context.** Don't read step files yourself. Don't read implementation code. Your job is coordination.
3. **Respect dependencies.** Never start a step before its dependencies are rebased in.
4. **Keep the user informed.** Report at each milestone: step started, implemented, reviewed, rebased.
5. **Preserve the original repo.** All work happens in worktrees. The user's working directory is never modified.
6. **Parallel when possible.** Independent steps should run in parallel (multiple Agent calls in one message).
7. **Verify invariants at every rebase.** You hold TDE expectations (from PLAN.md's Invariants section and the universal invariants). Verify them after each rebase — the test suite must pass, and no step may defer its tests. See `skills/test-driven-engineering/SKILL.md`.
8. **Linear history.** Never use `git merge` (except `--ff-only`). Always rebase step branches onto the orchestrator branch. The final history should be a clean linear sequence of commits.
9. **Clean up worktrees eagerly.** Remove implementor worktrees as soon as the implementor returns (after fetching their branch). Remove the orchestrator worktree during final cleanup. Don't leave stale worktrees behind.
