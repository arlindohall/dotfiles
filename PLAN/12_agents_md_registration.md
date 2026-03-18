# Step 12: Register new skills in AGENTS.md

## Goal

Add `agent-progress` and `agent-worktree` to the `<available_skills>` list in
`~/dotfiles/AGENTS.md` (which is symlinked or sourced as `~/.pi/agent/AGENTS.md`).

## Background

The `AGENTS.md` file contains an `<available_skills>` block that lists all skills
available to agents. Each skill entry has a name, description, and location path.

Two new skills need to be registered:
- `agent-progress` — task tracking CLI
- `agent-worktree` — worktree management

The existing skills list already has `memory`, `plan-author`, `plan-orchestrator`,
`plan-implementor`, `plan-reviewer`, and others. The new entries should be inserted in
alphabetical order.

## Tests (write BEFORE implementation)

Verification:

1. **Both skills appear in `<available_skills>`**: `agent-progress` and `agent-worktree`
2. **Entries are alphabetically ordered**: `agent-progress` before `agent-slack-read`,
   `agent-worktree` after `agent-slack-read`
3. **Each entry has name, description, and location**: matches the format of existing entries
4. **Paths are correct**: point to the actual SKILL.md files
5. **Existing entries are unchanged**: no modifications to other skill registrations

## Files to edit

### `~/.pi/agent/AGENTS.md`

In the `<available_skills>` block, add two new entries. The current block starts with:

```xml
<available_skills>
  <skill>
    <name>agent-slack-read</name>
```

Insert before `agent-slack-read` (alphabetically):

```xml
  <skill>
    <name>agent-progress</name>
    <description>Track agent task progress using a project-board-style CLI. Create, update, list, and display tasks with statuses, tags, and metadata. Use when starting work, reporting progress, flagging blockers, or when asked for a status update. Also provides a TUI board view via `agent-progress tui`.</description>
    <location>/Users/millerhall/.pi/agent/skills/agent-progress/SKILL.md</location>
  </skill>
```

Insert after `agent-slack-read` (alphabetically, before `code-review`):

```xml
  <skill>
    <name>agent-worktree</name>
    <description>Manages git worktrees for plan-based agent workflows. Provides scripts for creating orchestrator and step worktrees, fetching/removing them, rebasing, and running tests. Used by plan-orchestrator, plan-implementor, and other skills that work with git worktrees.</description>
    <location>/Users/millerhall/.pi/agent/skills/agent-worktree/SKILL.md</location>
  </skill>
```

## Acceptance criteria

- `agent-progress` appears in `<available_skills>` with correct name, description, and path
- `agent-worktree` appears in `<available_skills>` with correct name, description, and path
- Entries are in alphabetical order within the list
- Existing skill entries are unchanged
- The paths point to the actual SKILL.md files created in steps 7 and 8

## Dependencies

Steps 7, 8 — the skill files must exist before registering them.
