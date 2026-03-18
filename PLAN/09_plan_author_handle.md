# Step 9: Add `handle` frontmatter to PLAN.md format

## Goal

Update the plan-author skill to require a `handle` field in PLAN.md's YAML frontmatter.
This handle becomes the canonical identifier shared across worktree names, branch names,
task tracking, and memory tags.

## Background

Currently, `PLAN.md` uses a markdown heading format with no frontmatter:

```markdown
# PLAN: <title>

## Goal
...
```

The orchestrator derives a `PLAN_SLUG` ad hoc from the plan's goal. This step formalizes
that as a YAML frontmatter field called `handle`, making it explicit and authoritative.

After this change, PLAN.md will look like:

```markdown
---
handle: add-docker-support
---

# PLAN: Add Docker Support for the API

## Goal
...
```

The plan-author skill (in its Phase 3 PLAN.md format section) needs to:
1. Add YAML frontmatter with a required `handle` field
2. Document what the handle is: a short, lowercase, hyphenated slug
3. Document where it's used: worktree naming, branch naming, task tracking, memory tags
4. All references to `PLAN_SLUG` in the plan-author skill become `handle`

## Tests (write BEFORE implementation)

This is a documentation-only step. Verification is structural:

1. **plan-author SKILL.md PLAN.md format section includes frontmatter** with `handle`
2. **Handle is documented as required** — not optional
3. **Handle format is specified**: lowercase, hyphenated, no spaces or special characters
4. **Usage contexts are listed**: worktree naming, branch naming, task tracking, memory
5. **No remaining references to `PLAN_SLUG`** in plan-author SKILL.md (replaced with `handle`)
6. **Step file format is unchanged** — only PLAN.md gets frontmatter

## Files to edit

### `~/.pi/agent/skills/plan-author/SKILL.md`

In the **Phase 3: Write the plan files** section, update the `PLAN.md` format:

**Before:**
```markdown
#### `PLAN.md` format

```markdown
# PLAN: <title>

## Goal
...
```
```

**After:**
```markdown
#### `PLAN.md` format

```markdown
---
handle: <short-lowercase-hyphenated-slug>
---

# PLAN: <title>

## Handle

The `handle` in the frontmatter is the canonical identifier for this plan. It is:

- **Lowercase and hyphenated**: e.g., `add-docker-support`, `refactor-auth-module`
- **Short**: 2–4 words, no more than 40 characters
- **Unique within the repo**: no two active plans share a handle

The handle is used everywhere this plan is referenced:
- **Worktree paths**: `../PROJECT-orch-<handle>/`, `../PROJECT-orch-<handle>-stepNN/`
- **Branch names**: `orch-<handle>`, `orch-<handle>-step-NN`
- **Task tracking**: the `plan` field in `agent-progress` tasks
- **Memory tags**: when saving memories related to this plan

Derive the handle from the plan's goal — take the key nouns/verbs and hyphenate them.

## Goal
...
```
```

Also update the Phase 2 section where it discusses step decomposition. If `PLAN_SLUG`
appears anywhere in the plan-author skill, replace it with `handle` and note that it
comes from PLAN.md frontmatter.

In the **Compatibility** section at the bottom, update the reference:

**Before:**
```markdown
The orchestrator reads `PLAN.md` for the step index and dependency graph
```

**After:**
```markdown
The orchestrator reads `PLAN.md` for the `handle` (from frontmatter), the step index,
and the dependency graph
```

## Acceptance criteria

- plan-author SKILL.md includes YAML frontmatter requirement for PLAN.md
- The `handle` field is documented as required with format constraints
- All four usage contexts are listed (worktrees, branches, tasks, memory)
- No remaining references to `PLAN_SLUG` in plan-author SKILL.md
- Step file format (`PLAN/NN_short_name.md`) is unchanged
- The example PLAN.md format in the skill includes frontmatter with `handle`

## Dependencies

None — this is a documentation change to the plan-author skill. Can run in parallel
with other steps.
