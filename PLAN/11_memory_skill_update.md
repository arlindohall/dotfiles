# Step 11: Update memory skill with out-of-scope discovery guidance

## Goal

Add guidance to the memory skill for when agents discover out-of-scope work during
task implementation. This is a lightweight documentation addition — the memory skill
remains independent of the plan-* skills (preserving the acyclic dependency graph).

## Background

The current memory skill SKILL.md has a "When to Save Memories" section with four
bullet points. This step adds a fifth scenario: discovering out-of-scope work.

The guidance should be general — it says "if you are using a task tracking tool" rather
than naming `agent-progress` specifically. This keeps the memory skill unaware of the
plan-* skills while still providing useful guidance for agents that are using both.

The `agent-progress` skill (step 8) already cross-references memory for this use case.
This step adds the complementary guidance from the memory side.

## Tests (write BEFORE implementation)

This is a documentation-only step. Verification:

1. **New bullet point exists** in the "When to Save Memories" section
2. **Wording is generic** — does not name `agent-progress` or plan-* skills
3. **Guidance is actionable** — describes what to save and how to keyword it
4. **Existing bullets are unchanged** — additive only
5. **No new skill dependencies introduced** — memory remains a standalone skill

## Files to edit

### `~/.pi/agent/skills/memory/SKILL.md`

In the "When to Save Memories" section, add a fifth bullet:

**Current:**
```markdown
## When to Save Memories

Save a memory when:
- The user states a preference or personal fact ("I prefer tabs", "deploy target is us-east-1")
- Important project context is established (repo conventions, architecture decisions)
- The user explicitly asks you to remember something
- A non-obvious discovery is made that would be useful in future sessions
```

**Updated:**
```markdown
## When to Save Memories

Save a memory when:
- The user states a preference or personal fact ("I prefer tabs", "deploy target is us-east-1")
- Important project context is established (repo conventions, architecture decisions)
- The user explicitly asks you to remember something
- A non-obvious discovery is made that would be useful in future sessions
- You discover work that is outside the scope of your current task — a bug, a needed
  refactor, a missing feature, or a dependency issue. Save a memory with keywords
  describing the affected area so it can be found later. If a task tracker is available,
  also create a task for it; the memory provides context that outlives the task.
```

## Acceptance criteria

- The "When to Save Memories" section has 5 bullet points (was 4)
- The new bullet describes out-of-scope discovery without naming specific skills
- The guidance mentions saving with descriptive keywords
- The guidance mentions creating a task if a tracker is available (generic wording)
- No other sections of the memory SKILL.md are changed
- The memory skill has no new dependencies

## Dependencies

None — this is a standalone documentation change.
