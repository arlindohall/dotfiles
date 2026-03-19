---
name: agent-progress
description: >
  Track agent task progress using a project-board-style CLI. Create, update, list,
  and display tasks with statuses, tags, and metadata. Use when starting work,
  reporting progress, or flagging blockers. The CLI also has a TUI board view.
version: 0.1.0
---

# Agent Progress

Track task progress across agent sessions using the `agent-progress` CLI.
Data lives in `~/agent_progress.sqlite`.

## When to Use

**Create a task when:**
- You are starting a unit of work (a plan step, an investigation, a fix)
- You are delegating work to a sub-agent and want to track it
- A human asks you to track something

**Update a task when:**
- You begin working on it (→ `in-progress`)
- You finish it (→ `done`)
- You are blocked and need agent-side resolution (→ `agent-blocked`)
- You need human input to proceed (→ `pending-human-response`)
- You discover additional context (update description, add tags)

**List/show tasks when:**
- You want to see the current state of work
- You are resuming a session and need to recall what's in progress
- A human asks for a status update

## Status Values

| Status | Meaning | When to use |
|--------|---------|-------------|
| `todo` | Not started | Task created but work hasn't begun |
| `in-progress` | Actively being worked on | Agent is currently implementing |
| `done` | Complete | Work finished, tests pass, committed |
| `agent-blocked` | Blocked on agent-resolvable issue | Dependency failed, need rework, error in prior step |
| `pending-human-response` | Waiting for human input | Need a decision, clarification, or approval |

## CLI Reference

### Create a task

```bash
agent-progress create \
  --title "Implement login endpoint" \
  --repo dotfiles \
  --plan add-auth \
  --worktree "../dotfiles-orch-add-auth-step01" \
  --description "POST /login with JWT token generation" \
  --status in-progress \
  --tag auth --tag api
```

All flags except `--title` are optional. Default status is `todo`.
Output: the created task in YAML.

### Update a task

```bash
agent-progress update 5 --status done
agent-progress update 5 --description "Updated approach: using sessions instead of JWT"
agent-progress update 5 --status pending-human-response
```

Only the provided fields are changed. `updated_at` is auto-set.
When status changes to `done`, `completed_at` is auto-set.
Output: the updated task in YAML.

### Show a task

```bash
agent-progress show 5
agent-progress show 5 --format json
```

### List tasks

```bash
agent-progress list
agent-progress list --status in-progress
agent-progress list --repo dotfiles --plan add-auth
agent-progress list --tag urgent
agent-progress list --search "login"
agent-progress list --format json
```

Filters compose with AND. Output: task list in YAML (default) or JSON.
Summary line (e.g., "3 tasks found") prints to stderr.

### Tag / untag

```bash
agent-progress tag 5 urgent
agent-progress untag 5 urgent
```

### TUI board view

```bash
agent-progress tui
```

Opens a terminal board with columns for each status. Read-only.
Keys: ←/→ columns, ↑/↓ cards, / search, Esc clear, q quit.

## Task Fields

| Field | Description |
|-------|-------------|
| `id` | Auto-assigned integer |
| `title` | Short description of the task (required) |
| `description` | Longer context about the task |
| `status` | One of the five status values above |
| `repo` | Repository name (e.g., `dotfiles`) |
| `plan` | Plan handle from PLAN.md frontmatter (e.g., `add-auth`) |
| `worktree` | Git worktree path (follows agent-worktree naming) |
| `github_issue_url` | Full URL to a GitHub issue, if known |
| `tags` | Free-form tags for filtering and communication |
| `created_at` | Auto-set on creation |
| `updated_at` | Auto-set on every update |
| `completed_at` | Auto-set when status becomes `done`, cleared on reopen |

## Integration with Memory

If you discover something out of scope while working on a task — a bug, a needed
refactor, a missing feature — and it doesn't fit the current task, consider:

1. Creating a new `agent-progress` task for it (status `todo`)
2. Saving a memory about it (see the `memory` skill) if it's context that should
   persist across sessions

These two actions serve different purposes: a task is trackable work; a memory is
persistent knowledge. Use both when appropriate.

## Output Format

Default output is YAML — lightweight on tokens and human-readable.
Use `--format json` when you need structured parsing.

All commands that return task data write the task(s) to stdout.
Summary/status messages go to stderr.
