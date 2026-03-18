# Step 3: CLI command parsing

## Goal

Implement the `clap`-based CLI command structure: `create`, `update`, `show`, `list`,
`tag`, `untag`, and `tui` subcommands. Wire each command to the database layer and
produce output. This step focuses on argument parsing and the dispatch logic — output
formatting is kept minimal (YAML default) and refined in step 4.

## Background

The CLI binary is `agent-progress`. It uses `clap` with derive macros. The database path
defaults to `~/agent_progress.sqlite` and can be overridden with `--db` for testing.

Commands:
- `create --title <t> [--repo <r>] [--plan <p>] [--worktree <w>] [--github-issue-url <u>] [--description <d>] [--status <s>] [--tag <t>]...`
- `update <id> [--title <t>] [--repo <r>] [--plan <p>] [--worktree <w>] [--github-issue-url <u>] [--description <d>] [--status <s>]`
- `show <id> [--format yaml|json]`
- `list [--status <s>] [--repo <r>] [--plan <p>] [--tag <t>] [--search <q>] [--format yaml|json]`
- `tag <id> <tag>`
- `untag <id> <tag>`
- `tui` (placeholder in this step — implemented in step 6)

Default output format is YAML. `--format json` switches to JSON.

`create` prints the created task's YAML/JSON to stdout.
`update` prints the updated task's YAML/JSON to stdout.
`show` prints a single task.
`list` prints a list of tasks.
`tag`/`untag` print a confirmation message.

## Tests (write BEFORE implementation)

### Argument parsing tests (functional core — tests the clap structs, no I/O)

1. **`test_parse_create_minimal`**
   - Input: `["agent-progress", "create", "--title", "Do the thing"]`
   - Expected: parses to `Command::Create` with title `"Do the thing"`, all other fields at defaults
   - Why: minimal create works

2. **`test_parse_create_full`**
   - Input: `["agent-progress", "create", "--title", "Full task", "--repo", "dotfiles", "--plan", "my-plan", "--worktree", "../wt", "--github-issue-url", "https://github.com/o/r/issues/1", "--description", "A desc", "--status", "in-progress", "--tag", "rust", "--tag", "cli"]`
   - Expected: all fields populated, tags = `["rust", "cli"]`
   - Why: full-arg creation parses correctly

3. **`test_parse_create_missing_title_fails`**
   - Input: `["agent-progress", "create"]`
   - Expected: parse error (title is required)
   - Why: enforces required field

4. **`test_parse_update`**
   - Input: `["agent-progress", "update", "5", "--status", "done", "--description", "Updated desc"]`
   - Expected: `Command::Update` with id=5, status=Some(done), description=Some("Updated desc"), other fields None
   - Why: partial updates work

5. **`test_parse_show`**
   - Input: `["agent-progress", "show", "3"]`
   - Expected: `Command::Show` with id=3, format=Yaml (default)
   - Why: show parses task ID

6. **`test_parse_show_json`**
   - Input: `["agent-progress", "show", "3", "--format", "json"]`
   - Expected: `Command::Show` with id=3, format=Json
   - Why: format flag works

7. **`test_parse_list_with_filters`**
   - Input: `["agent-progress", "list", "--status", "todo", "--repo", "dotfiles", "--tag", "urgent", "--search", "auth"]`
   - Expected: `Command::List` with all four filters set
   - Why: list filters parse correctly

8. **`test_parse_list_no_filters`**
   - Input: `["agent-progress", "list"]`
   - Expected: `Command::List` with all filters None, format=Yaml
   - Why: bare list works

9. **`test_parse_tag`**
   - Input: `["agent-progress", "tag", "5", "urgent"]`
   - Expected: `Command::Tag` with id=5, tag="urgent"
   - Why: tag subcommand parses

10. **`test_parse_untag`**
    - Input: `["agent-progress", "untag", "5", "urgent"]`
    - Expected: `Command::Untag` with id=5, tag="urgent"
    - Why: untag subcommand parses

11. **`test_parse_tui`**
    - Input: `["agent-progress", "tui"]`
    - Expected: `Command::Tui`
    - Why: TUI subcommand parses

### Integration tests (with real in-memory database)

12. **`test_run_create_and_show`**
    - Setup: in-memory db
    - Input: run create with title "Test task", capture output; then run show with the returned id
    - Expected: show output contains `"Test task"` and valid YAML
    - Why: end-to-end create → show

13. **`test_run_list_empty`**
    - Setup: in-memory db
    - Input: run list
    - Expected: output is `[]\n` (empty YAML list)
    - Why: empty list doesn't crash

14. **`test_run_update_status`**
    - Setup: create a task, then update its status to `done`
    - Expected: show output has `status: done` and `completed_at` is non-null
    - Why: verifies update wiring including completed_at auto-set

15. **`test_run_tag_and_untag`**
    - Setup: create a task, tag it with `"hot"`, verify show includes the tag, untag it, verify tag removed
    - Expected: tag appears then disappears
    - Why: tag/untag wiring works

## Files to create

### `rust/agent-progress/src/cli.rs` (imperative shell — dispatch logic)

Replace the placeholder with the full CLI module:

```rust
use clap::{Parser, Subcommand, ValueEnum};
use crate::domain::Status;

#[derive(Parser, Debug)]
#[command(name = "agent-progress", version, about = "Agent task progress tracker")]
pub struct Cli {
    /// Path to SQLite database (default: ~/agent_progress.sqlite)
    #[arg(long, global = true, default_value_t = default_db_path())]
    pub db: String,

    #[command(subcommand)]
    pub command: Command,
}

fn default_db_path() -> String {
    let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
    format!("{home}/agent_progress.sqlite")
}

#[derive(Debug, Clone, ValueEnum)]
pub enum OutputFormat {
    Yaml,
    Json,
}

#[derive(Subcommand, Debug)]
pub enum Command {
    /// Create a new task
    Create {
        #[arg(long)]
        title: String,
        #[arg(long, default_value = "")]
        repo: String,
        #[arg(long, default_value = "")]
        plan: String,
        #[arg(long, default_value = "")]
        worktree: String,
        #[arg(long, default_value = "")]
        github_issue_url: String,
        #[arg(long, default_value = "")]
        description: String,
        #[arg(long, default_value = "todo")]
        status: String,
        #[arg(long)]
        tag: Vec<String>,
        #[arg(long, value_enum, default_value = "yaml")]
        format: OutputFormat,
    },
    /// Update an existing task
    Update {
        id: i64,
        #[arg(long)]
        title: Option<String>,
        #[arg(long)]
        repo: Option<String>,
        #[arg(long)]
        plan: Option<String>,
        #[arg(long)]
        worktree: Option<String>,
        #[arg(long)]
        github_issue_url: Option<String>,
        #[arg(long)]
        description: Option<String>,
        #[arg(long)]
        status: Option<String>,
        #[arg(long, value_enum, default_value = "yaml")]
        format: OutputFormat,
    },
    /// Show a single task by ID
    Show {
        id: i64,
        #[arg(long, value_enum, default_value = "yaml")]
        format: OutputFormat,
    },
    /// List tasks with optional filters
    List {
        #[arg(long)]
        status: Option<String>,
        #[arg(long)]
        repo: Option<String>,
        #[arg(long)]
        plan: Option<String>,
        #[arg(long)]
        tag: Option<String>,
        #[arg(long)]
        search: Option<String>,
        #[arg(long, value_enum, default_value = "yaml")]
        format: OutputFormat,
    },
    /// Add a tag to a task
    Tag {
        id: i64,
        tag: String,
    },
    /// Remove a tag from a task
    Untag {
        id: i64,
        tag: String,
    },
    /// Open the TUI board view
    Tui,
}

// run() function that dispatches each Command variant to the db layer
// and formats output. Implementation by the implementor.
pub fn run(cli: Cli) -> Result<(), Box<dyn std::error::Error>> {
    todo!()
}
```

## Files to edit

### `rust/agent-progress/src/main.rs`

Replace the placeholder main with CLI dispatch:

```rust
mod cli;
mod db;
mod domain;
mod tui;

use clap::Parser;

fn main() {
    let cli = cli::Cli::parse();
    if let Err(e) = cli::run(cli) {
        eprintln!("Error: {e}");
        std::process::exit(1);
    }
}
```

## Acceptance criteria

- `cargo test` passes with all 15 CLI tests green
- `cargo clippy` has no warnings
- `agent-progress create --title "Hello"` creates a task and prints YAML to stdout
- `agent-progress show 1` prints a task in YAML
- `agent-progress list` prints a list (possibly empty) in YAML
- `agent-progress list --format json` prints JSON
- `agent-progress update 1 --status done` updates and prints the task
- `agent-progress tag 1 urgent` and `agent-progress untag 1 urgent` work
- `agent-progress tui` is a recognized subcommand (can print a placeholder message for now)
- `--db /tmp/test.sqlite` overrides the database path
- Missing required args produce helpful clap error messages

## Dependencies

Steps 0, 1, 2 — needs domain types and database operations.
