# Step 2: Database layer

## Goal

Implement the SQLite database layer: initialization (applying the schema), and CRUD
operations for tasks and tags. The database module is the imperative shell — it owns the
`rusqlite::Connection` and translates between SQL rows and domain `Task` structs.

## Background

The schema SQL is defined in `db/schema.rs` (step 0). This step adds `db/ops.rs` which
provides functions that accept a `&Connection` and perform operations. By accepting the
connection as a parameter, tests can pass in an in-memory SQLite database.

The database path is `~/agent_progress.sqlite`. Database initialization creates the file
if it doesn't exist and applies the schema idempotently (all `CREATE TABLE IF NOT EXISTS`).

When a task transitions to `done`, `completed_at` should be auto-set to now. When it
transitions away from `done`, `completed_at` should be cleared. `updated_at` is always
set to now on any update.

Tags are stored in a separate `tags` table with a foreign key to `tasks.id`. The
`create_task` function accepts an initial set of tags. Tags can be added/removed
independently via `add_tag` and `remove_tag`.

## Tests (write BEFORE implementation)

These are integration tests — they exercise real SQLite (in-memory) and verify behavior
end-to-end through the database layer.

### Initialization

1. **`test_init_db_creates_tables`**
   - Setup: open an in-memory connection, call `init_db(&conn)`
   - Expected: querying `sqlite_master` for table names includes `tasks`, `tags`, `schema_version`
   - Why: validates that `init_db` applies the schema

2. **`test_init_db_is_idempotent`**
   - Setup: call `init_db(&conn)` twice on the same connection
   - Expected: no error, tables exist
   - Why: ensures `IF NOT EXISTS` clauses work

3. **`test_init_db_seeds_version`**
   - Setup: `init_db(&conn)`, then `SELECT version FROM schema_version`
   - Expected: returns `1`
   - Why: verifies the version seed

### Create

4. **`test_create_task_returns_id`**
   - Input: create a task with title `"Build CLI"`
   - Expected: returns `Ok(id)` where `id > 0`
   - Why: basic creation succeeds

5. **`test_create_task_with_all_fields`**
   - Input: create with repo=`"dotfiles"`, plan=`"agent-progress"`, worktree=`"../dotfiles-orch-agent-progress"`,
     github_issue_url=`"https://github.com/user/repo/issues/5"`, title=`"Full task"`,
     description=`"All fields set"`, status=`InProgress`, tags=`["rust", "cli"]`
   - Expected: `get_task` returns a task matching all fields, with two tags
   - Why: exercises full-field creation and tag association

6. **`test_create_task_sets_timestamps`**
   - Input: create a task
   - Expected: `created_at` and `updated_at` are non-empty ISO 8601 strings, `completed_at` is `None`
   - Why: verifies automatic timestamp behavior

7. **`test_create_task_empty_title_fails`**
   - Input: create with title `""`
   - Expected: returns `Err`
   - Why: validates the CHECK constraint on title

### Read

8. **`test_get_task_found`**
   - Input: create a task, then `get_task(id)`
   - Expected: returns `Some(task)` with matching fields
   - Why: basic retrieval

9. **`test_get_task_not_found`**
   - Input: `get_task(99999)` on an initialized but empty db
   - Expected: returns `None`
   - Why: non-existent ID returns None, not an error

10. **`test_get_task_includes_tags`**
    - Input: create task with tags `["alpha", "beta"]`, then `get_task(id)`
    - Expected: returned task's `tags` field contains `["alpha", "beta"]` (order may vary)
    - Why: verifies tag join in the read path

### List

11. **`test_list_tasks_empty`**
    - Input: `list_tasks` on empty db
    - Expected: returns empty vec
    - Why: no tasks → empty list

12. **`test_list_tasks_returns_all`**
    - Input: create 3 tasks, then `list_tasks` with no filters
    - Expected: returns 3 tasks
    - Why: basic listing

13. **`test_list_tasks_filter_by_status`**
    - Input: create tasks with statuses `todo`, `in-progress`, `done`, then filter by `status = "in-progress"`
    - Expected: returns 1 task with status `InProgress`
    - Why: status filter works

14. **`test_list_tasks_filter_by_repo`**
    - Input: create tasks in repo `"dotfiles"` and `"other"`, filter by `repo = "dotfiles"`
    - Expected: returns only the dotfiles tasks
    - Why: repo filter works

15. **`test_list_tasks_filter_by_plan`**
    - Input: create tasks with plans `"alpha"` and `"beta"`, filter by `plan = "alpha"`
    - Expected: returns only alpha tasks
    - Why: plan filter works

16. **`test_list_tasks_filter_by_tag`**
    - Input: create task with tag `"urgent"` and another without, filter by `tag = "urgent"`
    - Expected: returns only the tagged task
    - Why: tag filter requires a join

17. **`test_list_tasks_filter_by_search`**
    - Input: create tasks "Build the CLI" and "Write docs", search for `"cli"`
    - Expected: returns only the first task (case-insensitive match on title or description)
    - Why: free-text search works

18. **`test_list_tasks_combined_filters`**
    - Input: create tasks with varying repos, statuses, and tags; apply repo + status filter
    - Expected: returns only tasks matching both
    - Why: filters compose with AND semantics

### Update

19. **`test_update_task_status`**
    - Input: create a `todo` task, update status to `in-progress`
    - Expected: `get_task` shows `InProgress`, `updated_at` changed
    - Why: basic status update

20. **`test_update_task_sets_completed_at_on_done`**
    - Input: create a task, update status to `done`
    - Expected: `completed_at` is set to a non-None ISO 8601 string
    - Why: `completed_at` auto-populates on terminal status

21. **`test_update_task_clears_completed_at_on_reopen`**
    - Input: create a task, set to `done` (completed_at gets set), then set to `in-progress`
    - Expected: `completed_at` is `None` again
    - Why: reopening clears the completion timestamp

22. **`test_update_task_description`**
    - Input: create a task with description `"old"`, update to `"new"`
    - Expected: `description` is `"new"`
    - Why: non-status fields can be updated

23. **`test_update_nonexistent_task`**
    - Input: `update_task(99999, ...)` on empty db
    - Expected: returns `Err` or indicates no rows affected
    - Why: graceful handling of missing task

### Tags

24. **`test_add_tag`**
    - Input: create a task, `add_tag(task_id, "urgent")`
    - Expected: `get_task` includes `"urgent"` in tags
    - Why: tag addition works

25. **`test_add_duplicate_tag_is_idempotent`**
    - Input: `add_tag(task_id, "urgent")` twice
    - Expected: no error, task has `"urgent"` once
    - Why: UNIQUE constraint → idempotent

26. **`test_remove_tag`**
    - Input: create task with tag `"urgent"`, `remove_tag(task_id, "urgent")`
    - Expected: `get_task` tags is empty
    - Why: tag removal works

27. **`test_remove_nonexistent_tag_is_ok`**
    - Input: `remove_tag(task_id, "nope")` for a task without that tag
    - Expected: no error
    - Why: removing a missing tag is a no-op

## Files to create

### `rust/agent-progress/src/db/ops.rs` (imperative shell)

```rust
use rusqlite::{params, Connection, Result as SqlResult};
use crate::domain::{Status, Task};
use crate::db::schema::schema_sql;

pub fn init_db(conn: &Connection) -> SqlResult<()> {
    conn.execute_batch(schema_sql())
}

pub fn create_task(
    conn: &Connection,
    title: &str,
    description: &str,
    repo: &str,
    plan: &str,
    worktree: &str,
    github_issue_url: &str,
    status: &Status,
    tags: &[String],
) -> SqlResult<i64> {
    conn.execute(
        "INSERT INTO tasks (title, description, repo, plan, worktree, github_issue_url, status)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        params![title, description, repo, plan, worktree, github_issue_url, status.to_string()],
    )?;
    let task_id = conn.last_insert_rowid();
    for tag in tags {
        conn.execute(
            "INSERT OR IGNORE INTO tags (task_id, tag) VALUES (?1, ?2)",
            params![task_id, tag],
        )?;
    }
    Ok(task_id)
}

pub struct TaskFilters<'a> {
    pub status: Option<&'a str>,
    pub repo: Option<&'a str>,
    pub plan: Option<&'a str>,
    pub tag: Option<&'a str>,
    pub search: Option<&'a str>,
}

impl<'a> Default for TaskFilters<'a> {
    fn default() -> Self {
        Self { status: None, repo: None, plan: None, tag: None, search: None }
    }
}

pub fn list_tasks(conn: &Connection, filters: &TaskFilters) -> SqlResult<Vec<Task>> {
    // Build query dynamically based on which filters are set.
    // JOIN tags table only if tag filter is present.
    // Search is case-insensitive LIKE on title and description.
    // Implementation assembles WHERE clauses and parameters.
    // ... (full implementation by implementor)
    todo!()
}

pub fn get_task(conn: &Connection, id: i64) -> SqlResult<Option<Task>> {
    // Query task by id, join tags, return None if not found.
    // ... (full implementation by implementor)
    todo!()
}

pub struct TaskUpdate<'a> {
    pub title: Option<&'a str>,
    pub description: Option<&'a str>,
    pub repo: Option<&'a str>,
    pub plan: Option<&'a str>,
    pub worktree: Option<&'a str>,
    pub github_issue_url: Option<&'a str>,
    pub status: Option<Status>,
}

impl<'a> Default for TaskUpdate<'a> {
    fn default() -> Self {
        Self {
            title: None, description: None, repo: None, plan: None,
            worktree: None, github_issue_url: None, status: None,
        }
    }
}

pub fn update_task(conn: &Connection, id: i64, update: &TaskUpdate) -> SqlResult<()> {
    // Build SET clause dynamically for provided fields.
    // Always set updated_at = now.
    // If status is being set to Done, set completed_at = now.
    // If status is being set to non-Done, clear completed_at.
    // Return error if no rows affected.
    // ... (full implementation by implementor)
    todo!()
}

pub fn add_tag(conn: &Connection, task_id: i64, tag: &str) -> SqlResult<()> {
    conn.execute(
        "INSERT OR IGNORE INTO tags (task_id, tag) VALUES (?1, ?2)",
        params![task_id, tag],
    )?;
    Ok(())
}

pub fn remove_tag(conn: &Connection, task_id: i64, tag: &str) -> SqlResult<()> {
    conn.execute(
        "DELETE FROM tags WHERE task_id = ?1 AND tag = ?2",
        params![task_id, tag],
    )?;
    Ok(())
}

fn tags_for_task(conn: &Connection, task_id: i64) -> SqlResult<Vec<String>> {
    let mut stmt = conn.prepare("SELECT tag FROM tags WHERE task_id = ?1 ORDER BY tag")?;
    let tags = stmt.query_map(params![task_id], |row| row.get(0))?
        .collect::<SqlResult<Vec<String>>>()?;
    Ok(tags)
}

fn row_to_task(row: &rusqlite::Row, tags: Vec<String>) -> SqlResult<Task> {
    Ok(Task {
        id: Some(row.get("id")?),
        repo: row.get("repo")?,
        plan: row.get("plan")?,
        worktree: row.get("worktree")?,
        github_issue_url: row.get("github_issue_url")?,
        title: row.get("title")?,
        description: row.get("description")?,
        status: row.get::<_, String>("status")?
            .parse()
            .map_err(|e: String| rusqlite::Error::InvalidParameterName(e))?,
        tags,
        created_at: row.get("created_at")?,
        updated_at: row.get("updated_at")?,
        completed_at: row.get("completed_at")?,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn setup() -> Connection {
        let conn = Connection::open_in_memory().unwrap();
        init_db(&conn).unwrap();
        conn
    }

    // All 27 tests listed in the Tests section above go here.
    // The implementor writes them based on the specifications.
}
```

## Files to edit

### `rust/agent-progress/src/db/mod.rs`

Add the `ops` module:

```rust
pub mod ops;
pub mod schema;
```

## Acceptance criteria

- `cargo test` passes with all 27 database tests green
- `cargo clippy` has no warnings
- `init_db` is idempotent and seeds schema version 1
- `create_task` enforces non-empty title via the DB constraint
- `get_task` returns `None` for missing IDs (not an error)
- `list_tasks` supports filtering by status, repo, plan, tag, and free-text search, composable with AND
- `update_task` auto-manages `completed_at` and `updated_at`
- Tags are idempotent on add and silent on remove-nonexistent
- All tests use in-memory SQLite — no files written to disk

## Dependencies

Steps 0 and 1 — needs the schema SQL and the `Task`/`Status` domain types.
