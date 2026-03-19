use crate::db::ops::{
    add_tag, create_task, get_task, init_db, list_tasks, remove_tag, update_task, TaskFilters,
    TaskUpdate,
};
use crate::domain::{format_task_json, format_task_list_json, format_task_list_yaml, format_task_yaml, Status};
use clap::{Parser, Subcommand, ValueEnum};
use rusqlite::Connection;
use std::str::FromStr;

#[derive(Parser, Debug)]
#[command(name = "agent-progress", version, about = "Agent task progress tracker")]
pub struct Cli {
    #[arg(long, global = true, default_value_t = default_db_path())]
    pub db: String,

    #[command(subcommand)]
    pub command: Command,
}

fn default_db_path() -> String {
    let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
    format!("{home}/agent_progress.sqlite")
}

#[derive(Debug, Clone, ValueEnum, PartialEq)]
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
    Tag { id: i64, tag: String },
    /// Remove a tag from a task
    Untag { id: i64, tag: String },
    /// Open the TUI board view
    Tui,
}

pub fn run(cli: Cli) -> Result<(), Box<dyn std::error::Error>> {
    if let Command::Tui = &cli.command {
        println!("TUI not yet implemented");
        return Ok(());
    }

    let conn = Connection::open(&cli.db)?;
    init_db(&conn)?;

    match cli.command {
        Command::Create {
            title,
            repo,
            plan,
            worktree,
            github_issue_url,
            description,
            status,
            tag,
            format,
        } => {
            let parsed_status = Status::from_str(&status)?;
            let id = create_task(
                &conn,
                &title,
                &description,
                &repo,
                &plan,
                &worktree,
                &github_issue_url,
                &parsed_status,
                &tag,
            )?;
            let task = get_task(&conn, id)?.ok_or("task not found after create")?;
            let out = match format {
                OutputFormat::Json => format_task_json(&task)?,
                OutputFormat::Yaml => format_task_yaml(&task)?,
            };
            print!("{out}");
        }
        Command::Update {
            id,
            title,
            repo,
            plan,
            worktree,
            github_issue_url,
            description,
            status,
            format,
        } => {
            let parsed_status = status
                .as_deref()
                .map(Status::from_str)
                .transpose()
                .map_err(|e: String| e)?;
            update_task(
                &conn,
                id,
                &TaskUpdate {
                    title: title.as_deref(),
                    description: description.as_deref(),
                    repo: repo.as_deref(),
                    plan: plan.as_deref(),
                    worktree: worktree.as_deref(),
                    github_issue_url: github_issue_url.as_deref(),
                    status: parsed_status,
                },
            )?;
            let task = get_task(&conn, id)?.ok_or("task not found after update")?;
            let out = match format {
                OutputFormat::Json => format_task_json(&task)?,
                OutputFormat::Yaml => format_task_yaml(&task)?,
            };
            print!("{out}");
        }
        Command::Show { id, format } => {
            let task = get_task(&conn, id)?.ok_or_else(|| format!("task {id} not found"))?;
            let out = match format {
                OutputFormat::Json => format_task_json(&task)?,
                OutputFormat::Yaml => format_task_yaml(&task)?,
            };
            print!("{out}");
        }
        Command::List {
            status,
            repo,
            plan,
            tag,
            search,
            format,
        } => {
            let tasks = list_tasks(
                &conn,
                &TaskFilters {
                    status: status.as_deref(),
                    repo: repo.as_deref(),
                    plan: plan.as_deref(),
                    tag: tag.as_deref(),
                    search: search.as_deref(),
                },
            )?;
            let out = match format {
                OutputFormat::Json => format_task_list_json(&tasks)?,
                OutputFormat::Yaml => format_task_list_yaml(&tasks)?,
            };
            print!("{out}");
        }
        Command::Tag { id, tag } => {
            add_tag(&conn, id, &tag)?;
            println!("Tagged task {id} with '{tag}'");
        }
        Command::Untag { id, tag } => {
            remove_tag(&conn, id, &tag)?;
            println!("Removed tag '{tag}' from task {id}");
        }
        Command::Tui => unreachable!(),
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::Parser;

    fn parse(args: &[&str]) -> Result<Cli, clap::Error> {
        Cli::try_parse_from(args)
    }

    #[test]
    fn test_parse_create_minimal() {
        let cli = parse(&["agent-progress", "create", "--title", "Do the thing"]).unwrap();
        match cli.command {
            Command::Create {
                title,
                repo,
                plan,
                worktree,
                github_issue_url,
                description,
                status,
                tag,
                format,
            } => {
                assert_eq!(title, "Do the thing");
                assert_eq!(repo, "");
                assert_eq!(plan, "");
                assert_eq!(worktree, "");
                assert_eq!(github_issue_url, "");
                assert_eq!(description, "");
                assert_eq!(status, "todo");
                assert!(tag.is_empty());
                assert_eq!(format, OutputFormat::Yaml);
            }
            _ => panic!("expected Create"),
        }
    }

    #[test]
    fn test_parse_create_full() {
        let cli = parse(&[
            "agent-progress",
            "create",
            "--title",
            "Full task",
            "--repo",
            "dotfiles",
            "--plan",
            "my-plan",
            "--worktree",
            "../wt",
            "--github-issue-url",
            "https://github.com/o/r/issues/1",
            "--description",
            "A desc",
            "--status",
            "in-progress",
            "--tag",
            "rust",
            "--tag",
            "cli",
        ])
        .unwrap();
        match cli.command {
            Command::Create {
                title,
                repo,
                plan,
                worktree,
                github_issue_url,
                description,
                status,
                tag,
                ..
            } => {
                assert_eq!(title, "Full task");
                assert_eq!(repo, "dotfiles");
                assert_eq!(plan, "my-plan");
                assert_eq!(worktree, "../wt");
                assert_eq!(github_issue_url, "https://github.com/o/r/issues/1");
                assert_eq!(description, "A desc");
                assert_eq!(status, "in-progress");
                assert_eq!(tag, vec!["rust", "cli"]);
            }
            _ => panic!("expected Create"),
        }
    }

    #[test]
    fn test_parse_create_missing_title_fails() {
        assert!(parse(&["agent-progress", "create"]).is_err());
    }

    #[test]
    fn test_parse_update() {
        let cli = parse(&[
            "agent-progress",
            "update",
            "5",
            "--status",
            "done",
            "--description",
            "Updated desc",
        ])
        .unwrap();
        match cli.command {
            Command::Update {
                id,
                status,
                description,
                title,
                repo,
                plan,
                ..
            } => {
                assert_eq!(id, 5);
                assert_eq!(status, Some("done".to_string()));
                assert_eq!(description, Some("Updated desc".to_string()));
                assert_eq!(title, None);
                assert_eq!(repo, None);
                assert_eq!(plan, None);
            }
            _ => panic!("expected Update"),
        }
    }

    #[test]
    fn test_parse_show() {
        let cli = parse(&["agent-progress", "show", "3"]).unwrap();
        match cli.command {
            Command::Show { id, format } => {
                assert_eq!(id, 3);
                assert_eq!(format, OutputFormat::Yaml);
            }
            _ => panic!("expected Show"),
        }
    }

    #[test]
    fn test_parse_show_json() {
        let cli = parse(&["agent-progress", "show", "3", "--format", "json"]).unwrap();
        match cli.command {
            Command::Show { id, format } => {
                assert_eq!(id, 3);
                assert_eq!(format, OutputFormat::Json);
            }
            _ => panic!("expected Show"),
        }
    }

    #[test]
    fn test_parse_list_with_filters() {
        let cli = parse(&[
            "agent-progress",
            "list",
            "--status",
            "todo",
            "--repo",
            "dotfiles",
            "--tag",
            "urgent",
            "--search",
            "auth",
        ])
        .unwrap();
        match cli.command {
            Command::List {
                status,
                repo,
                tag,
                search,
                ..
            } => {
                assert_eq!(status, Some("todo".to_string()));
                assert_eq!(repo, Some("dotfiles".to_string()));
                assert_eq!(tag, Some("urgent".to_string()));
                assert_eq!(search, Some("auth".to_string()));
            }
            _ => panic!("expected List"),
        }
    }

    #[test]
    fn test_parse_list_no_filters() {
        let cli = parse(&["agent-progress", "list"]).unwrap();
        match cli.command {
            Command::List {
                status,
                repo,
                plan,
                tag,
                search,
                format,
            } => {
                assert_eq!(status, None);
                assert_eq!(repo, None);
                assert_eq!(plan, None);
                assert_eq!(tag, None);
                assert_eq!(search, None);
                assert_eq!(format, OutputFormat::Yaml);
            }
            _ => panic!("expected List"),
        }
    }

    #[test]
    fn test_parse_tag() {
        let cli = parse(&["agent-progress", "tag", "5", "urgent"]).unwrap();
        match cli.command {
            Command::Tag { id, tag } => {
                assert_eq!(id, 5);
                assert_eq!(tag, "urgent");
            }
            _ => panic!("expected Tag"),
        }
    }

    #[test]
    fn test_parse_untag() {
        let cli = parse(&["agent-progress", "untag", "5", "urgent"]).unwrap();
        match cli.command {
            Command::Untag { id, tag } => {
                assert_eq!(id, 5);
                assert_eq!(tag, "urgent");
            }
            _ => panic!("expected Untag"),
        }
    }

    #[test]
    fn test_parse_tui() {
        let cli = parse(&["agent-progress", "tui"]).unwrap();
        assert!(matches!(cli.command, Command::Tui));
    }

    fn make_conn() -> Connection {
        let conn = Connection::open_in_memory().unwrap();
        init_db(&conn).unwrap();
        conn
    }

    fn run_with_conn(
        conn: &Connection,
        command: Command,
    ) -> Result<String, Box<dyn std::error::Error>> {
        use crate::domain::{format_task_json, format_task_list_json, format_task_list_yaml, format_task_yaml, Status};
        use std::str::FromStr;

        match command {
            Command::Create {
                title,
                repo,
                plan,
                worktree,
                github_issue_url,
                description,
                status,
                tag,
                format,
            } => {
                let parsed_status = Status::from_str(&status)?;
                let id = create_task(
                    conn,
                    &title,
                    &description,
                    &repo,
                    &plan,
                    &worktree,
                    &github_issue_url,
                    &parsed_status,
                    &tag,
                )?;
                let task = get_task(conn, id)?.ok_or("not found")?;
                Ok(match format {
                    OutputFormat::Json => format_task_json(&task)?,
                    OutputFormat::Yaml => format_task_yaml(&task)?,
                })
            }
            Command::Update {
                id,
                title,
                repo,
                plan,
                worktree,
                github_issue_url,
                description,
                status,
                format,
            } => {
                let parsed_status = status
                    .as_deref()
                    .map(Status::from_str)
                    .transpose()
                    .map_err(|e: String| e)?;
                update_task(
                    conn,
                    id,
                    &TaskUpdate {
                        title: title.as_deref(),
                        description: description.as_deref(),
                        repo: repo.as_deref(),
                        plan: plan.as_deref(),
                        worktree: worktree.as_deref(),
                        github_issue_url: github_issue_url.as_deref(),
                        status: parsed_status,
                    },
                )?;
                let task = get_task(conn, id)?.ok_or("not found")?;
                Ok(match format {
                    OutputFormat::Json => format_task_json(&task)?,
                    OutputFormat::Yaml => format_task_yaml(&task)?,
                })
            }
            Command::Show { id, format } => {
                let task = get_task(conn, id)?.ok_or_else(|| format!("task {id} not found"))?;
                Ok(match format {
                    OutputFormat::Json => format_task_json(&task)?,
                    OutputFormat::Yaml => format_task_yaml(&task)?,
                })
            }
            Command::List {
                status,
                repo,
                plan,
                tag,
                search,
                format,
            } => {
                let tasks = list_tasks(
                    conn,
                    &TaskFilters {
                        status: status.as_deref(),
                        repo: repo.as_deref(),
                        plan: plan.as_deref(),
                        tag: tag.as_deref(),
                        search: search.as_deref(),
                    },
                )?;
                Ok(match format {
                    OutputFormat::Json => format_task_list_json(&tasks)?,
                    OutputFormat::Yaml => format_task_list_yaml(&tasks)?,
                })
            }
            Command::Tag { id, tag } => {
                add_tag(conn, id, &tag)?;
                Ok(format!("Tagged task {id} with '{tag}'"))
            }
            Command::Untag { id, tag } => {
                remove_tag(conn, id, &tag)?;
                Ok(format!("Removed tag '{tag}' from task {id}"))
            }
            Command::Tui => Ok("TUI not yet implemented".to_string()),
        }
    }

    #[test]
    fn test_run_create_and_show() {
        let conn = make_conn();
        let create_out = run_with_conn(
            &conn,
            Command::Create {
                title: "Test task".to_string(),
                repo: "".to_string(),
                plan: "".to_string(),
                worktree: "".to_string(),
                github_issue_url: "".to_string(),
                description: "".to_string(),
                status: "todo".to_string(),
                tag: vec![],
                format: OutputFormat::Yaml,
            },
        )
        .unwrap();
        assert!(create_out.contains("Test task"));

        let show_out = run_with_conn(
            &conn,
            Command::Show {
                id: 1,
                format: OutputFormat::Yaml,
            },
        )
        .unwrap();
        assert!(show_out.contains("Test task"));
    }

    #[test]
    fn test_run_list_empty() {
        let conn = make_conn();
        let out = run_with_conn(
            &conn,
            Command::List {
                status: None,
                repo: None,
                plan: None,
                tag: None,
                search: None,
                format: OutputFormat::Yaml,
            },
        )
        .unwrap();
        assert_eq!(out.trim(), "[]");
    }

    #[test]
    fn test_run_update_status() {
        let conn = make_conn();
        create_task(&conn, "Update me", "", "", "", "", "", &Status::Todo, &[]).unwrap();
        let out = run_with_conn(
            &conn,
            Command::Update {
                id: 1,
                title: None,
                repo: None,
                plan: None,
                worktree: None,
                github_issue_url: None,
                description: None,
                status: Some("done".to_string()),
                format: OutputFormat::Yaml,
            },
        )
        .unwrap();
        assert!(out.contains("done"));
        assert!(out.contains("completed_at"));
        assert!(!out.contains("completed_at: null"));
    }

    #[test]
    fn test_run_tag_and_untag() {
        let conn = make_conn();
        create_task(&conn, "Tag test", "", "", "", "", "", &Status::Todo, &[]).unwrap();

        run_with_conn(&conn, Command::Tag { id: 1, tag: "hot".to_string() }).unwrap();
        let show_out = run_with_conn(
            &conn,
            Command::Show {
                id: 1,
                format: OutputFormat::Yaml,
            },
        )
        .unwrap();
        assert!(show_out.contains("hot"));

        run_with_conn(&conn, Command::Untag { id: 1, tag: "hot".to_string() }).unwrap();
        let show_out2 = run_with_conn(
            &conn,
            Command::Show {
                id: 1,
                format: OutputFormat::Yaml,
            },
        )
        .unwrap();
        assert!(!show_out2.contains("hot"));
    }
}
