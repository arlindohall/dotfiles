# Step 10: Update plan-orchestrator, plan-implementor, plan-reviewer for progress + worktree refs

## Goal

Update the three plan execution skills to integrate with `agent-progress` for task
tracking and to reference `agent-worktree` for worktree scripts (completing the
migration started in step 7). This step adds progress-tracking behavior to the
orchestrator and implementor workflows, and ensures all three skills use consistent
`handle` terminology.

## Background

After steps 7 and 9, the agent-worktree skill owns all worktree scripts and PLAN.md
uses `handle` frontmatter. This step wires in the task-tracking behavior:

**plan-orchestrator** changes:
- Read `handle` from PLAN.md frontmatter (not derive PLAN_SLUG from the goal)
- Create a parent task via `agent-progress create` when starting a plan
- Create subtasks for each step before spawning the implementor
- Update task status as steps complete or fail
- Pass the task ID to implementors so they can update their own task

**plan-implementor** changes:
- Receive a task ID from the orchestrator
- Update the task to `in-progress` when starting
- Update to `done` when complete
- Update to `agent-blocked` if blocked
- Reference agent-worktree for worktree scripts

**plan-reviewer** changes:
- Minor: reference agent-worktree for naming conventions
- No progress tracking — the reviewer doesn't own tasks

### Dependency graph (acyclic)

```
agent-worktree ← plan-orchestrator → agent-progress
                 plan-implementor  → agent-progress
                 plan-reviewer
agent-progress → memory
```

Plan skills reference progress and worktree. Progress references memory.
Neither progress nor memory reference plan skills.

## Tests (write BEFORE implementation)

This is a documentation-only step. Verification:

1. **plan-orchestrator reads handle from frontmatter**: the Phase 1 section describes
   reading YAML frontmatter to extract `handle`
2. **plan-orchestrator creates parent task**: Phase 2 includes an `agent-progress create`
   call with the plan handle, repo, and a title derived from the plan goal
3. **plan-orchestrator creates step tasks**: Phase 3 includes task creation before
   spawning each implementor
4. **plan-orchestrator updates tasks on completion/failure**: Phase 3d describes updating
   task status after reviewer verdict
5. **plan-orchestrator passes TASK_ID to implementors**: the implementor prompt template
   includes a TASK_ID field
6. **plan-implementor updates task status**: process steps include `agent-progress update`
   calls for in-progress, done, and agent-blocked
7. **plan-implementor references agent-worktree**: worktree creation uses agent-worktree scripts
8. **plan-reviewer references agent-worktree**: naming convention references point to agent-worktree
9. **No remaining PLAN_SLUG references**: all three skills use `handle` / `PLAN_HANDLE`
10. **Dependencies section lists agent-progress and agent-worktree** in orchestrator and implementor

## Files to edit

### `~/.pi/agent/skills/plan-orchestrator/SKILL.md`

Major changes:

1. **Add Dependencies section** (near the top, after the description):

```markdown
## Skill Dependencies

- **agent-worktree** — worktree creation, cleanup, rebase, and test-running scripts
- **agent-progress** — task progress tracking for the plan and its steps
- **test-driven-engineering** — TDE principles for invariant verification
```

2. **Phase 1** — update step 1 to read `handle` from PLAN.md frontmatter:

```markdown
1. Read `PLAN.md` — but ONLY `PLAN.md`. Extract:
   - The `handle` from YAML frontmatter (this is the canonical plan identifier)
   - The overall goal (1-2 sentences)
   - The list of steps...
```

Replace all `PLAN_SLUG` with `PLAN_HANDLE` (the variable name used in scripts; its
value comes from the frontmatter `handle`).

3. **Phase 2** — after creating the orchestrator worktree, add task creation:

```markdown
### Create progress tasks

After setting up the orchestrator worktree, create a parent task for the plan:

```bash
PARENT_TASK_ID=$(agent-progress create \
  --title "Plan: <goal summary>" \
  --repo "${PROJECT_NAME}" \
  --plan "${PLAN_HANDLE}" \
  --worktree "${ORCH_WORKTREE}" \
  --status in-progress \
  --format yaml | grep 'id:' | awk '{print $2}')
```

Record `PARENT_TASK_ID` — you will reference it when reporting to the user.
```

4. **Phase 3b** — when spawning implementors, create a step task first:

```markdown
Before spawning the implementor, create a task for the step:

```bash
STEP_TASK_ID=$(agent-progress create \
  --title "Step ${STEP_ID}: <one-line description>" \
  --repo "${PROJECT_NAME}" \
  --plan "${PLAN_HANDLE}" \
  --worktree "${ORCH_WORKTREE}-step${STEP_ID}" \
  --status todo \
  --format yaml | grep 'id:' | awk '{print $2}')
```

Pass `STEP_TASK_ID` to the implementor in the prompt.
```

5. **Phase 3b implementor prompt template** — add `TASK_ID`:

```markdown
**TASK_ID**: {STEP_TASK_ID}
```

6. **Phase 3d** — after reviewer verdict, update the step task:

```markdown
- **If APPROVED**: Update the task:
  ```bash
  agent-progress update ${STEP_TASK_ID} --status done
  ```

- **If NEEDS_REWORK**: Update the task:
  ```bash
  agent-progress update ${STEP_TASK_ID} --status agent-blocked
  ```
```

7. **Phase 4** — on plan completion, update parent task:

```markdown
agent-progress update ${PARENT_TASK_ID} --status done
```

8. **Replace all script paths** with agent-worktree references (if not done in step 7).

### `~/.pi/agent/skills/plan-implementor/SKILL.md`

1. **Add Dependencies section**:

```markdown
## Skill Dependencies

- **agent-worktree** — worktree creation scripts
- **agent-progress** — task status updates
- **test-driven-engineering** — TDE principles for implementation
```

2. **Input section** — add `TASK_ID`:

```markdown
- **TASK_ID**: The agent-progress task ID for this step (for status updates)
```

3. **Process step 1** — reference agent-worktree:

```markdown
### 1. Create your worktree

Use the agent-worktree skill's setup script:

```bash
bash "${WORKTREE_SKILL_DIR}/scripts/setup-step-worktree.sh" "${REPO_ROOT}" "${ORCH_WORKTREE}" "${ORCH_BRANCH}" "${PLAN_HANDLE}" "${STEP_ID}"
```
```

4. **Process step 6** — add progress update at start:

```markdown
### 6. Implement (test-first)

First, update your task status:

```bash
agent-progress update ${TASK_ID} --status in-progress
```

Then follow the TDE cycle...
```

5. **Process step 9** — update task on completion:

```markdown
### 9. Report back

Update your task status:

```bash
agent-progress update ${TASK_ID} --status done
```

If you are blocked, instead:

```bash
agent-progress update ${TASK_ID} --status agent-blocked --description "Blocked: <reason>"
```
```

6. **Replace `PLAN_SLUG` with `PLAN_HANDLE`** everywhere.

### `~/.pi/agent/skills/plan-reviewer/SKILL.md`

1. **Replace `PLAN_SLUG` with `PLAN_HANDLE`** in any branch name references
2. **Add a note** referencing agent-worktree for worktree naming conventions
3. No progress tracking changes — the reviewer doesn't own tasks

## Acceptance criteria

- plan-orchestrator reads `handle` from PLAN.md frontmatter (documented in Phase 1)
- plan-orchestrator creates a parent task and per-step tasks via `agent-progress`
- plan-orchestrator updates task status on step completion or failure
- plan-orchestrator passes TASK_ID to implementors
- plan-implementor receives TASK_ID and updates status at start, completion, and on block
- plan-implementor references agent-worktree for worktree scripts
- plan-reviewer references agent-worktree for naming conventions
- No remaining `PLAN_SLUG` references in any of the three skills (all use `PLAN_HANDLE` or `handle`)
- Dependencies sections list the correct skill dependencies
- The dependency graph remains acyclic

## Dependencies

Steps 7, 8, 9 — needs agent-worktree skill (step 7), agent-progress skill (step 8),
and handle frontmatter convention (step 9).
