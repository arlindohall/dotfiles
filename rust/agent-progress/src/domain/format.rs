use crate::domain::Task;

pub fn summary_line(count: usize) -> String {
    match count {
        0 => "0 tasks found".to_string(),
        1 => "1 task found".to_string(),
        n => format!("{n} tasks found"),
    }
}

pub fn render_yaml(task: &Task) -> Result<String, serde_yaml::Error> {
    serde_yaml::to_string(task)
}

pub fn render_json(task: &Task) -> Result<String, serde_json::Error> {
    serde_json::to_string_pretty(task)
}

pub fn render_list_yaml(tasks: &[Task]) -> Result<String, serde_yaml::Error> {
    serde_yaml::to_string(tasks)
}

pub fn render_list_json(tasks: &[Task]) -> Result<String, serde_json::Error> {
    serde_json::to_string_pretty(tasks)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{Status, TaskBuilder};

    fn full_task() -> Task {
        TaskBuilder::new("Build it")
            .id(1)
            .repo("myrepo")
            .plan("my-plan")
            .worktree("../myrepo-orch")
            .github_issue_url("https://github.com/o/r/issues/1")
            .description("A description")
            .status(Status::Todo)
            .tags(vec!["alpha".to_string(), "beta".to_string()])
            .created_at("2026-03-19T10:00:00Z")
            .updated_at("2026-03-19T11:00:00Z")
            .completed_at("2026-03-19T12:00:00Z")
            .build()
            .unwrap()
    }

    #[test]
    fn test_format_single_task_yaml_field_order() {
        let task = TaskBuilder::new("Build it")
            .id(1)
            .status(Status::Todo)
            .build()
            .unwrap();
        let yaml = render_yaml(&task).unwrap();
        let id_pos = yaml.find("id:").unwrap();
        let title_pos = yaml.find("title:").unwrap();
        let status_pos = yaml.find("status:").unwrap();
        assert!(id_pos < title_pos, "id must come before title");
        assert!(title_pos < status_pos, "title must come before status");
    }

    #[test]
    fn test_format_single_task_json_is_valid() {
        let task = full_task();
        let json = render_json(&task).unwrap();
        let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert!(parsed.get("id").is_some());
        assert!(parsed.get("title").is_some());
        assert!(parsed.get("status").is_some());
        assert!(parsed.get("tags").is_some());
        assert!(parsed.get("completed_at").is_some());
    }

    #[test]
    fn test_format_empty_list_yaml() {
        let out = render_list_yaml(&[]).unwrap();
        assert_eq!(out.trim(), "[]");
    }

    #[test]
    fn test_format_empty_list_json() {
        let out = render_list_json(&[]).unwrap();
        assert_eq!(out.trim(), "[]");
    }

    #[test]
    fn test_format_list_yaml_contains_all_tasks() {
        let tasks = vec![
            TaskBuilder::new("Alpha").build().unwrap(),
            TaskBuilder::new("Beta").build().unwrap(),
        ];
        let yaml = render_list_yaml(&tasks).unwrap();
        assert!(yaml.contains("Alpha"));
        assert!(yaml.contains("Beta"));
    }

    #[test]
    fn test_format_summary_line_zero() {
        assert_eq!(summary_line(0), "0 tasks found");
    }

    #[test]
    fn test_format_summary_line_one() {
        assert_eq!(summary_line(1), "1 task found");
    }

    #[test]
    fn test_format_summary_line_many() {
        assert_eq!(summary_line(5), "5 tasks found");
    }

    #[test]
    fn test_format_task_yaml_tags_as_list() {
        let task = TaskBuilder::new("Tagged")
            .tags(vec!["alpha".to_string(), "beta".to_string()])
            .build()
            .unwrap();
        let yaml = render_yaml(&task).unwrap();
        assert!(yaml.contains("tags:"));
        assert!(yaml.contains("- alpha") || yaml.contains("alpha"));
        assert!(yaml.contains("- beta") || yaml.contains("beta"));
        assert!(!yaml.contains("alpha, beta"));
    }

    #[test]
    fn test_format_task_yaml_empty_optional_fields() {
        let task = TaskBuilder::new("Empty fields").build().unwrap();
        let yaml = render_yaml(&task).unwrap();
        assert!(yaml.contains("repo:"));
        assert!(yaml.contains("plan:"));
        assert!(yaml.contains("worktree:"));
        assert!(yaml.contains("github_issue_url:"));
        assert!(yaml.contains("completed_at:"));
        assert!(yaml.contains("null") || yaml.contains("~"));
    }
}
