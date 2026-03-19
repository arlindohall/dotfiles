pub mod format;

use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Status {
    Todo,
    InProgress,
    Done,
    AgentBlocked,
    PendingHumanResponse,
}

impl Status {
    pub fn all() -> &'static [Status] {
        &[
            Status::Todo,
            Status::InProgress,
            Status::Done,
            Status::AgentBlocked,
            Status::PendingHumanResponse,
        ]
    }

    pub fn is_terminal(self) -> bool {
        matches!(self, Status::Done)
    }
}

impl fmt::Display for Status {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Status::Todo => write!(f, "todo"),
            Status::InProgress => write!(f, "in-progress"),
            Status::Done => write!(f, "done"),
            Status::AgentBlocked => write!(f, "agent-blocked"),
            Status::PendingHumanResponse => write!(f, "pending-human-response"),
        }
    }
}

impl FromStr for Status {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "todo" => Ok(Status::Todo),
            "in-progress" => Ok(Status::InProgress),
            "done" => Ok(Status::Done),
            "agent-blocked" => Ok(Status::AgentBlocked),
            "pending-human-response" => Ok(Status::PendingHumanResponse),
            other => Err(format!(
                "invalid status: '{other}'. Valid values: todo, in-progress, done, agent-blocked, pending-human-response"
            )),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Task {
    pub id: Option<i64>,
    pub repo: String,
    pub plan: String,
    pub worktree: String,
    pub github_issue_url: String,
    pub title: String,
    pub description: String,
    pub status: Status,
    pub tags: Vec<String>,
    pub created_at: String,
    pub updated_at: String,
    pub completed_at: Option<String>,
}

pub struct TaskBuilder {
    id: Option<i64>,
    repo: String,
    plan: String,
    worktree: String,
    github_issue_url: String,
    title: String,
    description: String,
    status: Status,
    tags: Vec<String>,
    created_at: String,
    updated_at: String,
    completed_at: Option<String>,
}

impl TaskBuilder {
    pub fn new(title: &str) -> Self {
        Self {
            id: None,
            repo: String::new(),
            plan: String::new(),
            worktree: String::new(),
            github_issue_url: String::new(),
            title: title.to_string(),
            description: String::new(),
            status: Status::Todo,
            tags: Vec::new(),
            created_at: String::new(),
            updated_at: String::new(),
            completed_at: None,
        }
    }

    pub fn id(mut self, id: i64) -> Self {
        self.id = Some(id);
        self
    }
    pub fn repo(mut self, repo: &str) -> Self {
        self.repo = repo.to_string();
        self
    }
    pub fn plan(mut self, plan: &str) -> Self {
        self.plan = plan.to_string();
        self
    }
    pub fn worktree(mut self, worktree: &str) -> Self {
        self.worktree = worktree.to_string();
        self
    }
    pub fn github_issue_url(mut self, url: &str) -> Self {
        self.github_issue_url = url.to_string();
        self
    }
    pub fn description(mut self, desc: &str) -> Self {
        self.description = desc.to_string();
        self
    }
    pub fn status(mut self, status: Status) -> Self {
        self.status = status;
        self
    }
    pub fn tags(mut self, tags: Vec<String>) -> Self {
        self.tags = tags;
        self
    }
    pub fn created_at(mut self, ts: &str) -> Self {
        self.created_at = ts.to_string();
        self
    }
    pub fn updated_at(mut self, ts: &str) -> Self {
        self.updated_at = ts.to_string();
        self
    }
    pub fn completed_at(mut self, ts: &str) -> Self {
        self.completed_at = Some(ts.to_string());
        self
    }

    pub fn build(self) -> Result<Task, String> {
        if self.title.trim().is_empty() {
            return Err("title must not be empty".to_string());
        }
        Ok(Task {
            id: self.id,
            repo: self.repo,
            plan: self.plan,
            worktree: self.worktree,
            github_issue_url: self.github_issue_url,
            title: self.title,
            description: self.description,
            status: self.status,
            tags: self.tags,
            created_at: self.created_at,
            updated_at: self.updated_at,
            completed_at: self.completed_at,
        })
    }
}

pub fn format_task_yaml(task: &Task) -> Result<String, serde_yaml::Error> {
    serde_yaml::to_string(task)
}

pub fn format_task_json(task: &Task) -> Result<String, serde_json::Error> {
    serde_json::to_string_pretty(task)
}

pub fn format_task_list_yaml(tasks: &[Task]) -> Result<String, serde_yaml::Error> {
    serde_yaml::to_string(tasks)
}

pub fn format_task_list_json(tasks: &[Task]) -> Result<String, serde_json::Error> {
    serde_json::to_string_pretty(tasks)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_status_from_str_valid_values() {
        assert_eq!("todo".parse::<Status>().unwrap(), Status::Todo);
        assert_eq!("in-progress".parse::<Status>().unwrap(), Status::InProgress);
        assert_eq!("done".parse::<Status>().unwrap(), Status::Done);
        assert_eq!("agent-blocked".parse::<Status>().unwrap(), Status::AgentBlocked);
        assert_eq!(
            "pending-human-response".parse::<Status>().unwrap(),
            Status::PendingHumanResponse
        );
    }

    #[test]
    fn test_status_from_str_invalid() {
        assert!("blocked".parse::<Status>().is_err());
        assert!("DONE".parse::<Status>().is_err());
        assert!("".parse::<Status>().is_err());
        assert!("unknown".parse::<Status>().is_err());
    }

    #[test]
    fn test_status_display() {
        assert_eq!(Status::Todo.to_string(), "todo");
        assert_eq!(Status::InProgress.to_string(), "in-progress");
        assert_eq!(Status::Done.to_string(), "done");
        assert_eq!(Status::AgentBlocked.to_string(), "agent-blocked");
        assert_eq!(Status::PendingHumanResponse.to_string(), "pending-human-response");
    }

    #[test]
    fn test_status_is_terminal() {
        assert!(!Status::Todo.is_terminal());
        assert!(!Status::InProgress.is_terminal());
        assert!(Status::Done.is_terminal());
        assert!(!Status::AgentBlocked.is_terminal());
        assert!(!Status::PendingHumanResponse.is_terminal());
    }

    #[test]
    fn test_status_all_returns_five_variants() {
        let all = Status::all();
        assert_eq!(all.len(), 5);
        assert!(all.contains(&Status::Todo));
        assert!(all.contains(&Status::InProgress));
        assert!(all.contains(&Status::Done));
        assert!(all.contains(&Status::AgentBlocked));
        assert!(all.contains(&Status::PendingHumanResponse));
    }

    #[test]
    fn test_task_builder_minimal() {
        let task = TaskBuilder::new("Implement auth").build().unwrap();
        assert_eq!(task.title, "Implement auth");
        assert_eq!(task.status, Status::Todo);
        assert_eq!(task.id, None);
        assert!(task.repo.is_empty());
        assert!(task.plan.is_empty());
        assert!(task.worktree.is_empty());
        assert!(task.github_issue_url.is_empty());
        assert!(task.description.is_empty());
        assert!(task.tags.is_empty());
        assert_eq!(task.completed_at, None);
    }

    #[test]
    fn test_task_builder_full() {
        let task = TaskBuilder::new("Add login endpoint")
            .id(7)
            .repo("dotfiles")
            .plan("add-auth")
            .worktree("../dotfiles-orch-add-auth-step01")
            .github_issue_url("https://github.com/org/repo/issues/42")
            .description("POST /login with JWT")
            .status(Status::InProgress)
            .tags(vec!["auth".to_string(), "api".to_string()])
            .created_at("2026-03-19T10:00:00Z")
            .updated_at("2026-03-19T11:00:00Z")
            .completed_at("2026-03-19T12:00:00Z")
            .build()
            .unwrap();

        assert_eq!(task.id, Some(7));
        assert_eq!(task.repo, "dotfiles");
        assert_eq!(task.plan, "add-auth");
        assert_eq!(task.worktree, "../dotfiles-orch-add-auth-step01");
        assert_eq!(task.github_issue_url, "https://github.com/org/repo/issues/42");
        assert_eq!(task.title, "Add login endpoint");
        assert_eq!(task.description, "POST /login with JWT");
        assert_eq!(task.status, Status::InProgress);
        assert_eq!(task.tags, vec!["auth", "api"]);
        assert_eq!(task.created_at, "2026-03-19T10:00:00Z");
        assert_eq!(task.updated_at, "2026-03-19T11:00:00Z");
        assert_eq!(task.completed_at, Some("2026-03-19T12:00:00Z".to_string()));
    }

    #[test]
    fn test_task_builder_rejects_empty_title() {
        assert!(TaskBuilder::new("").build().is_err());
        assert!(TaskBuilder::new("   ").build().is_err());
    }

    #[test]
    fn test_task_to_yaml_contains_all_fields() {
        let task = make_full_task();
        let yaml = format_task_yaml(&task).unwrap();
        for key in &[
            "id:",
            "repo:",
            "plan:",
            "worktree:",
            "github_issue_url:",
            "title:",
            "description:",
            "status:",
            "tags:",
            "created_at:",
            "updated_at:",
            "completed_at:",
        ] {
            assert!(yaml.contains(key), "YAML must contain key: {key}");
        }
    }

    #[test]
    fn test_task_to_json_roundtrip() {
        let task = make_full_task();
        let json = format_task_json(&task).unwrap();
        let deserialized: Task = serde_json::from_str(&json).unwrap();
        assert_eq!(task, deserialized);
    }

    #[test]
    fn test_task_list_to_yaml() {
        let tasks = vec![
            TaskBuilder::new("First").build().unwrap(),
            TaskBuilder::new("Second").build().unwrap(),
        ];
        let yaml = format_task_list_yaml(&tasks).unwrap();
        assert!(yaml.contains("First"));
        assert!(yaml.contains("Second"));
    }

    #[test]
    fn test_task_to_yaml_handles_none_completed_at() {
        let task = TaskBuilder::new("No completion").build().unwrap();
        let yaml = format_task_yaml(&task).unwrap();
        assert!(yaml.contains("completed_at"));
        assert!(yaml.contains("null") || !yaml.contains("completed_at: 2"));
    }

    fn make_full_task() -> Task {
        TaskBuilder::new("Full task")
            .id(1)
            .repo("myrepo")
            .plan("my-plan")
            .worktree("../myrepo-orch-my-plan")
            .github_issue_url("https://github.com/org/repo/issues/1")
            .description("A full task")
            .status(Status::InProgress)
            .tags(vec!["tag1".to_string()])
            .created_at("2026-03-19T10:00:00Z")
            .updated_at("2026-03-19T11:00:00Z")
            .completed_at("2026-03-19T12:00:00Z")
            .build()
            .unwrap()
    }
}
