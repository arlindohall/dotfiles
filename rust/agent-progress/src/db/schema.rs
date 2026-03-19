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
