use crate::domain::{Status, Task};

pub struct BoardState {
    tasks: Vec<Task>,
    filter: String,
    active_column: usize,
    column_selections: [usize; 5],
}

impl BoardState {
    pub fn new(tasks: Vec<Task>) -> Self {
        Self {
            tasks,
            filter: String::new(),
            active_column: 0,
            column_selections: [0; 5],
        }
    }

    pub fn column_statuses() -> &'static [Status; 5] {
        &[
            Status::Todo,
            Status::InProgress,
            Status::Done,
            Status::AgentBlocked,
            Status::PendingHumanResponse,
        ]
    }

    pub fn filtered_tasks(&self) -> Vec<&Task> {
        if self.filter.is_empty() {
            return self.tasks.iter().collect();
        }
        let needle = self.filter.to_lowercase();
        self.tasks
            .iter()
            .filter(|t| {
                t.title.to_lowercase().contains(&needle)
                    || t.description.to_lowercase().contains(&needle)
                    || t.repo.to_lowercase().contains(&needle)
                    || t.plan.to_lowercase().contains(&needle)
                    || t.tags.iter().any(|tag| tag.to_lowercase().contains(&needle))
            })
            .collect()
    }

    pub fn tasks_for_column(&self, status: Status) -> Vec<&Task> {
        self.filtered_tasks()
            .into_iter()
            .filter(|t| t.status == status)
            .collect()
    }

    pub fn set_filter(&mut self, filter: &str) {
        self.filter = filter.to_string();
        self.column_selections = [0; 5];
    }

    pub fn clear_filter(&mut self) {
        self.set_filter("");
    }

    pub fn filter(&self) -> &str {
        &self.filter
    }

    pub fn active_column(&self) -> usize {
        self.active_column
    }

    pub fn selected_card(&self) -> usize {
        self.column_selections[self.active_column]
    }

    pub fn move_column_right(&mut self) {
        let prev_sel = self.column_selections[self.active_column];
        self.active_column = (self.active_column + 1) % 5;
        self.column_selections[self.active_column] = prev_sel;
        self.clamp_selection();
    }

    pub fn move_column_left(&mut self) {
        let prev_sel = self.column_selections[self.active_column];
        self.active_column = if self.active_column == 0 {
            4
        } else {
            self.active_column - 1
        };
        self.column_selections[self.active_column] = prev_sel;
        self.clamp_selection();
    }

    pub fn move_card_down(&mut self) {
        let max = self.active_column_task_count().saturating_sub(1);
        let sel = &mut self.column_selections[self.active_column];
        *sel = (*sel + 1).min(max);
    }

    pub fn move_card_up(&mut self) {
        let sel = &mut self.column_selections[self.active_column];
        *sel = sel.saturating_sub(1);
    }

    pub fn active_task(&self) -> Option<&Task> {
        let status = Self::column_statuses()[self.active_column];
        let tasks = self.tasks_for_column(status);
        tasks.into_iter().nth(self.column_selections[self.active_column])
    }

    fn active_column_task_count(&self) -> usize {
        let status = Self::column_statuses()[self.active_column];
        self.tasks_for_column(status).len()
    }

    fn clamp_selection(&mut self) {
        let max = self.active_column_task_count().saturating_sub(1);
        let sel = &mut self.column_selections[self.active_column];
        *sel = (*sel).min(max);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::TaskBuilder;

    fn task(title: &str, status: Status) -> Task {
        TaskBuilder::new(title).status(status).build().unwrap()
    }

    fn task_with_desc(title: &str, desc: &str, status: Status) -> Task {
        TaskBuilder::new(title).description(desc).status(status).build().unwrap()
    }

    fn task_with_repo(title: &str, repo: &str, status: Status) -> Task {
        TaskBuilder::new(title).repo(repo).status(status).build().unwrap()
    }

    fn task_with_plan(title: &str, plan: &str, status: Status) -> Task {
        TaskBuilder::new(title).plan(plan).status(status).build().unwrap()
    }

    fn task_with_tags(title: &str, tags: Vec<String>, status: Status) -> Task {
        TaskBuilder::new(title).tags(tags).status(status).build().unwrap()
    }

    #[test]
    fn test_new_board_state_defaults() {
        let tasks = vec![
            task("Task 1", Status::Todo),
            task("Task 2", Status::InProgress),
            task("Task 3", Status::Done),
        ];
        let board = BoardState::new(tasks);
        assert_eq!(board.filter(), "");
        assert_eq!(board.active_column(), 0);
        assert_eq!(board.selected_card(), 0);
    }

    #[test]
    fn test_new_board_state_empty_tasks() {
        let board = BoardState::new(vec![]);
        let statuses = BoardState::column_statuses();
        assert_eq!(statuses.len(), 5);
        for &status in statuses.iter() {
            assert_eq!(board.tasks_for_column(status).len(), 0);
        }
    }

    #[test]
    fn test_filtered_tasks_no_filter() {
        let tasks = vec![
            task("A", Status::Todo),
            task("B", Status::InProgress),
            task("C", Status::Done),
        ];
        let board = BoardState::new(tasks);
        assert_eq!(board.filtered_tasks().len(), 3);
    }

    #[test]
    fn test_filtered_tasks_by_title() {
        let tasks = vec![
            task("Build CLI", Status::Todo),
            task("Write docs", Status::Todo),
            task("Build API", Status::Todo),
        ];
        let mut board = BoardState::new(tasks);
        board.set_filter("build");
        assert_eq!(board.filtered_tasks().len(), 2);
    }

    #[test]
    fn test_filtered_tasks_by_description() {
        let tasks = vec![
            task_with_desc("Task A", "database migration needed", Status::Todo),
            task_with_desc("Task B", "simple fix", Status::Todo),
        ];
        let mut board = BoardState::new(tasks);
        board.set_filter("migration");
        assert_eq!(board.filtered_tasks().len(), 1);
        assert_eq!(board.filtered_tasks()[0].title, "Task A");
    }

    #[test]
    fn test_filtered_tasks_by_repo() {
        let tasks = vec![
            task_with_repo("Task A", "dotfiles", Status::Todo),
            task_with_repo("Task B", "webapp", Status::Todo),
        ];
        let mut board = BoardState::new(tasks);
        board.set_filter("dotfiles");
        assert_eq!(board.filtered_tasks().len(), 1);
        assert_eq!(board.filtered_tasks()[0].repo, "dotfiles");
    }

    #[test]
    fn test_filtered_tasks_by_plan() {
        let tasks = vec![
            task_with_plan("Task A", "add-auth", Status::Todo),
            task_with_plan("Task B", "fix-bug", Status::Todo),
        ];
        let mut board = BoardState::new(tasks);
        board.set_filter("auth");
        assert_eq!(board.filtered_tasks().len(), 1);
        assert_eq!(board.filtered_tasks()[0].plan, "add-auth");
    }

    #[test]
    fn test_filtered_tasks_case_insensitive() {
        let tasks = vec![task("Build CLI", Status::Todo)];
        let mut board = BoardState::new(tasks);
        board.set_filter("BUILD");
        assert_eq!(board.filtered_tasks().len(), 1);
    }

    #[test]
    fn test_filtered_tasks_by_tag() {
        let tasks = vec![
            task_with_tags("Urgent task", vec!["urgent".to_string()], Status::Todo),
            task("Normal task", Status::Todo),
        ];
        let mut board = BoardState::new(tasks);
        board.set_filter("urgent");
        assert_eq!(board.filtered_tasks().len(), 1);
        assert_eq!(board.filtered_tasks()[0].title, "Urgent task");
    }

    #[test]
    fn test_tasks_for_column_groups_by_status() {
        let tasks = vec![
            task("Todo 1", Status::Todo),
            task("Todo 2", Status::Todo),
            task("In Progress 1", Status::InProgress),
            task("Done 1", Status::Done),
        ];
        let board = BoardState::new(tasks);
        assert_eq!(board.tasks_for_column(Status::Todo).len(), 2);
        assert_eq!(board.tasks_for_column(Status::InProgress).len(), 1);
        assert_eq!(board.tasks_for_column(Status::Done).len(), 1);
        assert_eq!(board.tasks_for_column(Status::AgentBlocked).len(), 0);
        assert_eq!(board.tasks_for_column(Status::PendingHumanResponse).len(), 0);
    }

    #[test]
    fn test_tasks_for_column_respects_filter() {
        let tasks = vec![
            task("Build CLI", Status::Todo),
            task("Write docs", Status::Todo),
        ];
        let mut board = BoardState::new(tasks);
        board.set_filter("cli");
        assert_eq!(board.tasks_for_column(Status::Todo).len(), 1);
    }

    #[test]
    fn test_column_order() {
        let statuses = BoardState::column_statuses();
        assert_eq!(statuses[0], Status::Todo);
        assert_eq!(statuses[1], Status::InProgress);
        assert_eq!(statuses[2], Status::Done);
        assert_eq!(statuses[3], Status::AgentBlocked);
        assert_eq!(statuses[4], Status::PendingHumanResponse);
    }

    #[test]
    fn test_move_column_right() {
        let mut board = BoardState::new(vec![]);
        board.move_column_right();
        assert_eq!(board.active_column(), 1);
    }

    #[test]
    fn test_move_column_right_wraps() {
        let mut board = BoardState::new(vec![]);
        board.active_column = 4;
        board.move_column_right();
        assert_eq!(board.active_column(), 0);
    }

    #[test]
    fn test_move_column_left() {
        let mut board = BoardState::new(vec![]);
        board.active_column = 1;
        board.move_column_left();
        assert_eq!(board.active_column(), 0);
    }

    #[test]
    fn test_move_column_left_wraps() {
        let mut board = BoardState::new(vec![]);
        board.move_column_left();
        assert_eq!(board.active_column(), 4);
    }

    #[test]
    fn test_move_card_down() {
        let tasks = vec![
            task("T1", Status::Todo),
            task("T2", Status::Todo),
            task("T3", Status::Todo),
        ];
        let mut board = BoardState::new(tasks);
        board.move_card_down();
        assert_eq!(board.selected_card(), 1);
    }

    #[test]
    fn test_move_card_down_clamps() {
        let tasks = vec![task("T1", Status::Todo), task("T2", Status::Todo)];
        let mut board = BoardState::new(tasks);
        board.column_selections[0] = 1;
        board.move_card_down();
        assert_eq!(board.selected_card(), 1);
    }

    #[test]
    fn test_move_card_up() {
        let tasks = vec![
            task("T1", Status::Todo),
            task("T2", Status::Todo),
            task("T3", Status::Todo),
        ];
        let mut board = BoardState::new(tasks);
        board.column_selections[0] = 2;
        board.move_card_up();
        assert_eq!(board.selected_card(), 1);
    }

    #[test]
    fn test_move_card_up_clamps() {
        let tasks = vec![task("T1", Status::Todo)];
        let mut board = BoardState::new(tasks);
        board.move_card_up();
        assert_eq!(board.selected_card(), 0);
    }

    #[test]
    fn test_column_switch_resets_selection_if_out_of_bounds() {
        let mut tasks: Vec<Task> = (0..5).map(|i| task(&format!("T{i}"), Status::Todo)).collect();
        tasks.push(task("IP1", Status::InProgress));
        tasks.push(task("IP2", Status::InProgress));
        let mut board = BoardState::new(tasks);
        board.column_selections[0] = 4;
        board.move_column_right();
        assert_eq!(board.active_column(), 1);
        assert_eq!(board.selected_card(), 1);
    }

    #[test]
    fn test_set_filter() {
        let tasks = vec![task("T1", Status::Todo), task("T2", Status::InProgress)];
        let mut board = BoardState::new(tasks);
        board.column_selections[0] = 0;
        board.set_filter("cli");
        assert_eq!(board.filter(), "cli");
        assert_eq!(board.column_selections, [0; 5]);
    }

    #[test]
    fn test_clear_filter() {
        let tasks = vec![task("Build CLI", Status::Todo), task("Write docs", Status::Todo)];
        let mut board = BoardState::new(tasks);
        board.set_filter("cli");
        assert_eq!(board.filtered_tasks().len(), 1);
        board.clear_filter();
        assert_eq!(board.filter(), "");
        assert_eq!(board.filtered_tasks().len(), 2);
    }

    #[test]
    fn test_active_task() {
        let tasks = vec![task("First", Status::Todo), task("Second", Status::Todo)];
        let mut board = BoardState::new(tasks);
        board.column_selections[0] = 1;
        let t = board.active_task().unwrap();
        assert_eq!(t.title, "Second");
    }

    #[test]
    fn test_active_task_empty_column() {
        let board = BoardState::new(vec![]);
        assert!(board.active_task().is_none());
    }
}
