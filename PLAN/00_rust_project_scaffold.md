# Step 0: Scaffold the Rust crate

## Goal

Create the `agent-progress` Rust project with its Cargo.toml, module structure, and
initial database schema definition. This step produces a compilable, installable crate
with an empty `main()` and the schema constant ready for later use.

## Background

The crate lives at `~/dotfiles/rust/agent-progress/`. There is an existing (empty)
`~/dotfiles/rust/gg/` directory, but no shared workspace — each crate is independent.

The binary will be installed via `cargo install --path rust/agent-progress` and will be
named `agent-progress`.

The database lives at `~/agent_progress.sqlite`. The schema includes a `schema_version`
table for forward-compatible migrations (unused now but present from day one).

## Tests (write BEFORE implementation)

### `src/db/schema.rs` tests (functional core — pure string output)

1. **`test_schema_sql_contains_tasks_table`**
   - Input: call `schema_sql()`
   - Expected: returned string contains `CREATE TABLE IF NOT EXISTS tasks`
   - Why: ensures the schema constant defines the tasks table

2. **`test_schema_sql_contains_tags_table`**
   - Input: call `schema_sql()`
   - Expected: returned string contains `CREATE TABLE IF NOT EXISTS tags`
   - Why: ensures the tags table is present

3. **`test_schema_sql_contains_schema_version_table`**
   - Input: call `schema_sql()`
   - Expected: returned string contains `CREATE TABLE IF NOT EXISTS schema_version`
   - Why: ensures the version table exists for future migrations

4. **`test_schema_sql_contains_initial_version_insert`**
   - Input: call `schema_sql()`
   - Expected: returned string contains `INSERT OR IGNORE INTO schema_version` with version `1`
   - Why: ensures the initial version seed is part of the schema

5. **`test_schema_sql_tasks_has_all_columns`**
   - Input: call `schema_sql()`
   - Expected: string contains each column name: `id`, `repo`, `plan`, `worktree`,
     `github_issue_url`, `title`, `description`, `status`, `created_at`, `updated_at`,
     `completed_at`
   - Why: catches missing columns early

## Files to create

### `rust/agent-progress/Cargo.toml`

```toml
[package]
name = "agent-progress"
version = "0.1.0"
edition = "2024"

[[bin]]
name = "agent-progress"
path = "src/main.rs"

[dependencies]
clap = { version = "4", features = ["derive"] }
rusqlite = { version = "0.35", features = ["bundled"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
serde_yaml = "0.9"
chrono = { version = "0.4", features = ["serde"] }
ratatui = "0.29"
crossterm = "0.29"

[dev-dependencies]
tempfile = "3"
```

### `rust/agent-progress/src/main.rs`

```rust
mod cli;
mod db;
mod domain;
mod tui;

fn main() {
    println!("agent-progress v0.1.0");
}
```

### `rust/agent-progress/src/cli.rs`

```rust
// CLI command parsing — populated in step 3
```

### `rust/agent-progress/src/domain.rs`

```rust
// Domain types — populated in step 1
```

### `rust/agent-progress/src/tui.rs`

```rust
// TUI module — populated in steps 5–6
```

### `rust/agent-progress/src/db/mod.rs`

```rust
pub mod schema;
```

### `rust/agent-progress/src/db/schema.rs` (functional core)

```rust
/// Returns the full SQL schema for initializing the agent_progress database.
/// This is a pure function that returns a static string — no I/O.
pub fn schema_sql() -> &'static str {
    r#"
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER PRIMARY KEY
);

INSERT OR IGNORE INTO schema_version (version) VALUES (1);

CREATE TABLE IF NOT EXISTS tasks (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    repo            TEXT NOT NULL DEFAULT '',
    plan            TEXT NOT NULL DEFAULT '',
    worktree        TEXT NOT NULL DEFAULT '',
    github_issue_url TEXT NOT NULL DEFAULT '',
    title           TEXT NOT NULL CHECK(length(title) > 0),
    description     TEXT NOT NULL DEFAULT '',
    status          TEXT NOT NULL DEFAULT 'todo' CHECK(status IN ('todo', 'in-progress', 'done', 'agent-blocked', 'pending-human-response')),
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    completed_at    TEXT
);

CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_plan ON tasks(plan);
CREATE INDEX IF NOT EXISTS idx_tasks_repo ON tasks(repo);

CREATE TABLE IF NOT EXISTS tags (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    tag     TEXT NOT NULL CHECK(length(tag) > 0),
    UNIQUE(task_id, tag)
);

CREATE INDEX IF NOT EXISTS idx_tags_tag ON tags(tag);
CREATE INDEX IF NOT EXISTS idx_tags_task_id ON tags(task_id);
"#
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_schema_sql_contains_tasks_table() {
        let sql = schema_sql();
        assert!(
            sql.contains("CREATE TABLE IF NOT EXISTS tasks"),
            "Schema must define the tasks table"
        );
    }

    #[test]
    fn test_schema_sql_contains_tags_table() {
        let sql = schema_sql();
        assert!(
            sql.contains("CREATE TABLE IF NOT EXISTS tags"),
            "Schema must define the tags table"
        );
    }

    #[test]
    fn test_schema_sql_contains_schema_version_table() {
        let sql = schema_sql();
        assert!(
            sql.contains("CREATE TABLE IF NOT EXISTS schema_version"),
            "Schema must define the schema_version table"
        );
    }

    #[test]
    fn test_schema_sql_contains_initial_version_insert() {
        let sql = schema_sql();
        assert!(
            sql.contains("INSERT OR IGNORE INTO schema_version (version) VALUES (1)"),
            "Schema must seed version 1"
        );
    }

    #[test]
    fn test_schema_sql_tasks_has_all_columns() {
        let sql = schema_sql();
        for col in &[
            "id", "repo", "plan", "worktree", "github_issue_url",
            "title", "description", "status", "created_at", "updated_at", "completed_at",
        ] {
            assert!(
                sql.contains(col),
                "tasks table must contain column: {col}"
            );
        }
    }
}
```

## Files to edit

None — all files are new.

## Acceptance criteria

- `cargo build` succeeds in `rust/agent-progress/`
- `cargo test` passes with all 5 schema tests green
- `cargo clippy` produces no warnings
- Running the binary prints `agent-progress v0.1.0`
- The module structure exists: `main.rs`, `cli.rs`, `domain.rs`, `tui.rs`, `db/mod.rs`, `db/schema.rs`
- `Cargo.toml` includes all dependencies needed for the full project (clap, rusqlite, serde, serde_json, serde_yaml, chrono, ratatui, crossterm)

## Dependencies

None — this is the first step.
