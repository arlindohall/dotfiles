#![allow(dead_code)]

use crate::db::schema::schema_sql;
use crate::domain::{Status, Task};
use rusqlite::{params, Connection, Result as SqlResult};

pub fn init_db(conn: &Connection) -> SqlResult<()> {
    conn.execute_batch(schema_sql())
}

#[allow(clippy::too_many_arguments)]
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
        params![
            title,
            description,
            repo,
            plan,
            worktree,
            github_issue_url,
            status.to_string()
        ],
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

#[derive(Default)]
pub struct TaskFilters<'a> {
    pub status: Option<&'a str>,
    pub repo: Option<&'a str>,
    pub plan: Option<&'a str>,
    pub tag: Option<&'a str>,
    pub search: Option<&'a str>,
}

pub fn list_tasks(conn: &Connection, filters: &TaskFilters) -> SqlResult<Vec<Task>> {
    let mut sql = String::from(
        "SELECT DISTINCT t.id, t.repo, t.plan, t.worktree, t.github_issue_url,
                t.title, t.description, t.status, t.created_at, t.updated_at, t.completed_at
         FROM tasks t",
    );
    let mut conditions: Vec<String> = Vec::new();

    if filters.tag.is_some() {
        sql.push_str(" JOIN tags tg ON t.id = tg.task_id");
    }

    if let Some(status) = filters.status {
        conditions.push(format!("t.status = '{}'", status.replace('\'', "''")));
    }
    if let Some(repo) = filters.repo {
        conditions.push(format!("t.repo = '{}'", repo.replace('\'', "''")));
    }
    if let Some(plan) = filters.plan {
        conditions.push(format!("t.plan = '{}'", plan.replace('\'', "''")));
    }
    if let Some(tag) = filters.tag {
        conditions.push(format!("tg.tag = '{}'", tag.replace('\'', "''")));
    }
    if let Some(search) = filters.search {
        let pattern = format!("%{}%", search.replace('\'', "''"));
        conditions.push(format!(
            "(t.title LIKE '{}' OR t.description LIKE '{}')",
            pattern, pattern
        ));
    }

    if !conditions.is_empty() {
        sql.push_str(" WHERE ");
        sql.push_str(&conditions.join(" AND "));
    }
    sql.push_str(" ORDER BY t.id");

    let mut stmt = conn.prepare(&sql)?;
    let task_ids: Vec<i64> = stmt
        .query_map([], |row| row.get(0))?
        .collect::<SqlResult<Vec<i64>>>()?;

    let mut tasks = Vec::new();
    for id in task_ids {
        if let Some(task) = get_task(conn, id)? {
            tasks.push(task);
        }
    }
    Ok(tasks)
}

pub fn get_task(conn: &Connection, id: i64) -> SqlResult<Option<Task>> {
    let mut stmt = conn.prepare(
        "SELECT id, repo, plan, worktree, github_issue_url,
                title, description, status, created_at, updated_at, completed_at
         FROM tasks WHERE id = ?1",
    )?;
    let result = stmt.query_row(params![id], |row| {
        let status_str: String = row.get("status")?;
        let status = status_str
            .parse::<Status>()
            .map_err(rusqlite::Error::InvalidParameterName)?;
        Ok(Task {
            id: Some(row.get("id")?),
            repo: row.get("repo")?,
            plan: row.get("plan")?,
            worktree: row.get("worktree")?,
            github_issue_url: row.get("github_issue_url")?,
            title: row.get("title")?,
            description: row.get("description")?,
            status,
            tags: Vec::new(),
            created_at: row.get("created_at")?,
            updated_at: row.get("updated_at")?,
            completed_at: row.get("completed_at")?,
        })
    });

    match result {
        Ok(mut task) => {
            task.tags = tags_for_task(conn, id)?;
            Ok(Some(task))
        }
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
        Err(e) => Err(e),
    }
}

#[derive(Default)]
pub struct TaskUpdate<'a> {
    pub title: Option<&'a str>,
    pub description: Option<&'a str>,
    pub repo: Option<&'a str>,
    pub plan: Option<&'a str>,
    pub worktree: Option<&'a str>,
    pub github_issue_url: Option<&'a str>,
    pub status: Option<Status>,
}

pub fn update_task(conn: &Connection, id: i64, update: &TaskUpdate) -> SqlResult<()> {
    let mut sets: Vec<String> = Vec::new();
    sets.push("updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')".to_string());

    if let Some(title) = update.title {
        sets.push(format!("title = '{}'", title.replace('\'', "''")));
    }
    if let Some(description) = update.description {
        sets.push(format!("description = '{}'", description.replace('\'', "''")));
    }
    if let Some(repo) = update.repo {
        sets.push(format!("repo = '{}'", repo.replace('\'', "''")));
    }
    if let Some(plan) = update.plan {
        sets.push(format!("plan = '{}'", plan.replace('\'', "''")));
    }
    if let Some(worktree) = update.worktree {
        sets.push(format!("worktree = '{}'", worktree.replace('\'', "''")));
    }
    if let Some(github_issue_url) = update.github_issue_url {
        sets.push(format!(
            "github_issue_url = '{}'",
            github_issue_url.replace('\'', "''")
        ));
    }
    if let Some(ref status) = update.status {
        sets.push(format!("status = '{status}'"));
        if status.is_terminal() {
            sets.push("completed_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')".to_string());
        } else {
            sets.push("completed_at = NULL".to_string());
        }
    }

    let sql = format!("UPDATE tasks SET {} WHERE id = ?1", sets.join(", "));
    let rows_affected = conn.execute(&sql, params![id])?;
    if rows_affected == 0 {
        return Err(rusqlite::Error::QueryReturnedNoRows);
    }
    Ok(())
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
    let mut stmt =
        conn.prepare("SELECT tag FROM tags WHERE task_id = ?1 ORDER BY tag")?;
    let tags = stmt
        .query_map(params![task_id], |row| row.get(0))?
        .collect::<SqlResult<Vec<String>>>()?;
    Ok(tags)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::Status;

    fn setup() -> Connection {
        let conn = Connection::open_in_memory().unwrap();
        init_db(&conn).unwrap();
        conn
    }

    fn make_task(conn: &Connection, title: &str) -> i64 {
        create_task(conn, title, "", "", "", "", "", &Status::Todo, &[]).unwrap()
    }

    #[test]
    fn test_init_db_creates_tables() {
        let conn = Connection::open_in_memory().unwrap();
        init_db(&conn).unwrap();
        let mut stmt = conn
            .prepare("SELECT name FROM sqlite_master WHERE type='table'")
            .unwrap();
        let names: Vec<String> = stmt
            .query_map([], |row| row.get(0))
            .unwrap()
            .filter_map(|r| r.ok())
            .collect();
        assert!(names.contains(&"tasks".to_string()));
        assert!(names.contains(&"tags".to_string()));
        assert!(names.contains(&"schema_version".to_string()));
    }

    #[test]
    fn test_init_db_is_idempotent() {
        let conn = Connection::open_in_memory().unwrap();
        init_db(&conn).unwrap();
        init_db(&conn).unwrap();
        let count: i64 = conn
            .query_row("SELECT COUNT(*) FROM tasks", [], |r| r.get(0))
            .unwrap();
        assert_eq!(count, 0);
    }

    #[test]
    fn test_init_db_seeds_version() {
        let conn = setup();
        let version: i64 = conn
            .query_row("SELECT version FROM schema_version", [], |r| r.get(0))
            .unwrap();
        assert_eq!(version, 1);
    }

    #[test]
    fn test_create_task_returns_id() {
        let conn = setup();
        let id = make_task(&conn, "Build CLI");
        assert!(id > 0);
    }

    #[test]
    fn test_create_task_with_all_fields() {
        let conn = setup();
        let id = create_task(
            &conn,
            "Full task",
            "All fields set",
            "dotfiles",
            "agent-progress",
            "../dotfiles-orch-agent-progress",
            "https://github.com/user/repo/issues/5",
            &Status::InProgress,
            &["rust".to_string(), "cli".to_string()],
        )
        .unwrap();
        let task = get_task(&conn, id).unwrap().unwrap();
        assert_eq!(task.title, "Full task");
        assert_eq!(task.description, "All fields set");
        assert_eq!(task.repo, "dotfiles");
        assert_eq!(task.plan, "agent-progress");
        assert_eq!(task.worktree, "../dotfiles-orch-agent-progress");
        assert_eq!(task.github_issue_url, "https://github.com/user/repo/issues/5");
        assert_eq!(task.status, Status::InProgress);
        assert_eq!(task.tags.len(), 2);
        assert!(task.tags.contains(&"rust".to_string()));
        assert!(task.tags.contains(&"cli".to_string()));
    }

    #[test]
    fn test_create_task_sets_timestamps() {
        let conn = setup();
        let id = make_task(&conn, "Timestamped task");
        let task = get_task(&conn, id).unwrap().unwrap();
        assert!(!task.created_at.is_empty());
        assert!(!task.updated_at.is_empty());
        assert_eq!(task.completed_at, None);
    }

    #[test]
    fn test_create_task_empty_title_fails() {
        let conn = setup();
        let result = create_task(&conn, "", "", "", "", "", "", &Status::Todo, &[]);
        assert!(result.is_err());
    }

    #[test]
    fn test_get_task_found() {
        let conn = setup();
        let id = make_task(&conn, "Find me");
        let task = get_task(&conn, id).unwrap();
        assert!(task.is_some());
        assert_eq!(task.unwrap().title, "Find me");
    }

    #[test]
    fn test_get_task_not_found() {
        let conn = setup();
        let task = get_task(&conn, 99999).unwrap();
        assert!(task.is_none());
    }

    #[test]
    fn test_get_task_includes_tags() {
        let conn = setup();
        let id = create_task(
            &conn,
            "Tagged task",
            "",
            "",
            "",
            "",
            "",
            &Status::Todo,
            &["alpha".to_string(), "beta".to_string()],
        )
        .unwrap();
        let task = get_task(&conn, id).unwrap().unwrap();
        assert_eq!(task.tags.len(), 2);
        assert!(task.tags.contains(&"alpha".to_string()));
        assert!(task.tags.contains(&"beta".to_string()));
    }

    #[test]
    fn test_list_tasks_empty() {
        let conn = setup();
        let tasks = list_tasks(&conn, &TaskFilters::default()).unwrap();
        assert!(tasks.is_empty());
    }

    #[test]
    fn test_list_tasks_returns_all() {
        let conn = setup();
        make_task(&conn, "Task 1");
        make_task(&conn, "Task 2");
        make_task(&conn, "Task 3");
        let tasks = list_tasks(&conn, &TaskFilters::default()).unwrap();
        assert_eq!(tasks.len(), 3);
    }

    #[test]
    fn test_list_tasks_filter_by_status() {
        let conn = setup();
        make_task(&conn, "Todo task");
        create_task(&conn, "In progress task", "", "", "", "", "", &Status::InProgress, &[])
            .unwrap();
        create_task(&conn, "Done task", "", "", "", "", "", &Status::Done, &[]).unwrap();
        let tasks = list_tasks(
            &conn,
            &TaskFilters {
                status: Some("in-progress"),
                ..Default::default()
            },
        )
        .unwrap();
        assert_eq!(tasks.len(), 1);
        assert_eq!(tasks[0].status, Status::InProgress);
    }

    #[test]
    fn test_list_tasks_filter_by_repo() {
        let conn = setup();
        create_task(&conn, "Dotfiles task", "", "dotfiles", "", "", "", &Status::Todo, &[])
            .unwrap();
        create_task(&conn, "Other task", "", "other", "", "", "", &Status::Todo, &[]).unwrap();
        let tasks = list_tasks(
            &conn,
            &TaskFilters {
                repo: Some("dotfiles"),
                ..Default::default()
            },
        )
        .unwrap();
        assert_eq!(tasks.len(), 1);
        assert_eq!(tasks[0].repo, "dotfiles");
    }

    #[test]
    fn test_list_tasks_filter_by_plan() {
        let conn = setup();
        create_task(&conn, "Alpha task", "", "", "alpha", "", "", &Status::Todo, &[]).unwrap();
        create_task(&conn, "Beta task", "", "", "beta", "", "", &Status::Todo, &[]).unwrap();
        let tasks = list_tasks(
            &conn,
            &TaskFilters {
                plan: Some("alpha"),
                ..Default::default()
            },
        )
        .unwrap();
        assert_eq!(tasks.len(), 1);
        assert_eq!(tasks[0].plan, "alpha");
    }

    #[test]
    fn test_list_tasks_filter_by_tag() {
        let conn = setup();
        create_task(&conn, "Urgent task", "", "", "", "", "", &Status::Todo, &[
            "urgent".to_string(),
        ])
        .unwrap();
        create_task(&conn, "Normal task", "", "", "", "", "", &Status::Todo, &[]).unwrap();
        let tasks = list_tasks(
            &conn,
            &TaskFilters {
                tag: Some("urgent"),
                ..Default::default()
            },
        )
        .unwrap();
        assert_eq!(tasks.len(), 1);
        assert_eq!(tasks[0].title, "Urgent task");
    }

    #[test]
    fn test_list_tasks_filter_by_search() {
        let conn = setup();
        make_task(&conn, "Build the CLI");
        make_task(&conn, "Write docs");
        let tasks = list_tasks(
            &conn,
            &TaskFilters {
                search: Some("cli"),
                ..Default::default()
            },
        )
        .unwrap();
        assert_eq!(tasks.len(), 1);
        assert_eq!(tasks[0].title, "Build the CLI");
    }

    #[test]
    fn test_list_tasks_combined_filters() {
        let conn = setup();
        create_task(&conn, "Match both", "", "dotfiles", "", "", "", &Status::InProgress, &[])
            .unwrap();
        create_task(&conn, "Wrong repo", "", "other", "", "", "", &Status::InProgress, &[])
            .unwrap();
        create_task(&conn, "Wrong status", "", "dotfiles", "", "", "", &Status::Todo, &[])
            .unwrap();
        let tasks = list_tasks(
            &conn,
            &TaskFilters {
                repo: Some("dotfiles"),
                status: Some("in-progress"),
                ..Default::default()
            },
        )
        .unwrap();
        assert_eq!(tasks.len(), 1);
        assert_eq!(tasks[0].title, "Match both");
    }

    #[test]
    fn test_update_task_status() {
        let conn = setup();
        let id = make_task(&conn, "Status updater");
        let before = get_task(&conn, id).unwrap().unwrap();
        update_task(
            &conn,
            id,
            &TaskUpdate {
                status: Some(Status::InProgress),
                ..Default::default()
            },
        )
        .unwrap();
        let after = get_task(&conn, id).unwrap().unwrap();
        assert_eq!(after.status, Status::InProgress);
        assert!(after.updated_at >= before.updated_at);
    }

    #[test]
    fn test_update_task_sets_completed_at_on_done() {
        let conn = setup();
        let id = make_task(&conn, "Complete me");
        update_task(
            &conn,
            id,
            &TaskUpdate {
                status: Some(Status::Done),
                ..Default::default()
            },
        )
        .unwrap();
        let task = get_task(&conn, id).unwrap().unwrap();
        assert!(task.completed_at.is_some());
        let ts = task.completed_at.unwrap();
        assert!(!ts.is_empty());
    }

    #[test]
    fn test_update_task_clears_completed_at_on_reopen() {
        let conn = setup();
        let id = make_task(&conn, "Reopen me");
        update_task(
            &conn,
            id,
            &TaskUpdate {
                status: Some(Status::Done),
                ..Default::default()
            },
        )
        .unwrap();
        update_task(
            &conn,
            id,
            &TaskUpdate {
                status: Some(Status::InProgress),
                ..Default::default()
            },
        )
        .unwrap();
        let task = get_task(&conn, id).unwrap().unwrap();
        assert_eq!(task.completed_at, None);
    }

    #[test]
    fn test_update_task_description() {
        let conn = setup();
        let id = create_task(&conn, "Describe me", "old", "", "", "", "", &Status::Todo, &[])
            .unwrap();
        update_task(
            &conn,
            id,
            &TaskUpdate {
                description: Some("new"),
                ..Default::default()
            },
        )
        .unwrap();
        let task = get_task(&conn, id).unwrap().unwrap();
        assert_eq!(task.description, "new");
    }

    #[test]
    fn test_update_nonexistent_task() {
        let conn = setup();
        let result = update_task(
            &conn,
            99999,
            &TaskUpdate {
                status: Some(Status::Done),
                ..Default::default()
            },
        );
        assert!(result.is_err());
    }

    #[test]
    fn test_add_tag() {
        let conn = setup();
        let id = make_task(&conn, "Tag me");
        add_tag(&conn, id, "urgent").unwrap();
        let task = get_task(&conn, id).unwrap().unwrap();
        assert!(task.tags.contains(&"urgent".to_string()));
    }

    #[test]
    fn test_add_duplicate_tag_is_idempotent() {
        let conn = setup();
        let id = make_task(&conn, "Duplicate tags");
        add_tag(&conn, id, "urgent").unwrap();
        add_tag(&conn, id, "urgent").unwrap();
        let task = get_task(&conn, id).unwrap().unwrap();
        let urgent_count = task.tags.iter().filter(|t| *t == "urgent").count();
        assert_eq!(urgent_count, 1);
    }

    #[test]
    fn test_remove_tag() {
        let conn = setup();
        let id = create_task(&conn, "Remove tag", "", "", "", "", "", &Status::Todo, &[
            "urgent".to_string(),
        ])
        .unwrap();
        remove_tag(&conn, id, "urgent").unwrap();
        let task = get_task(&conn, id).unwrap().unwrap();
        assert!(task.tags.is_empty());
    }

    #[test]
    fn test_remove_nonexistent_tag_is_ok() {
        let conn = setup();
        let id = make_task(&conn, "No tags");
        let result = remove_tag(&conn, id, "nope");
        assert!(result.is_ok());
    }
}
