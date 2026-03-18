# Step 5: TUI state management (functional core)

## Goal

Implement the pure state-management layer for the TUI: the board model, column layout
logic, search/filter application, and keyboard navigation state. All code in this step
is functional core — no terminal I/O, no ratatui, no crossterm.

## Background

The TUI displays tasks in a board layout with columns for each status:
`todo`, `in-progress`, `done`, `agent-blocked`, `pending-human-response`.

The board has:
- A search bar at the top that filters tasks in real time
- Columns for each status, each containing task cards
- Keyboard navigation: left/right to switch columns, up/down to scroll within a column,
  `/` to focus the search bar, `Esc` to clear search, `q` to quit

The state model is:
- `BoardState` — holds the full task list, the current filter string, the active column
  index, and the selected card index within each column
- Pure functions transform the state: `apply_filter`, `move_column_left`,
  `move_column_right`, `move_card_up`, `move_card_down`, `filtered_tasks`,
  `tasks_for_column`

This step tests all the state logic. Step 6 will render it with ratatui.

## Tests (write BEFORE implementation)

### Board state construction

1. **`test_new_board_state_defaults`**
   - Input: `BoardState::new(tasks)` with 3 tasks (one todo, one in-progress, one done)
   - Expected: `filter` is empty, `active_column` is 0, `selected_card` for each column is 0
   - Why: validates initial state

2. **`test_new_board_state_empty_tasks`**
   - Input: `BoardState::new(vec![])`
   - Expected: board has 5 columns (one per status), all empty
   - Why: empty board doesn't crash

### Filtering

3. **`test_filtered_tasks_no_filter`**
   - Input: board with 3 tasks, filter is `""`
   - Expected: `filtered_tasks()` returns all 3
   - Why: empty filter = no filtering

4. **`test_filtered_tasks_by_title`**
   - Input: tasks with titles "Build CLI", "Write docs", "Build API"; filter = `"build"`
   - Expected: returns 2 tasks (case-insensitive match on title)
   - Why: title search works

5. **`test_filtered_tasks_by_description`**
   - Input: tasks where one has description containing "database migration"; filter = `"migration"`
   - Expected: returns that one task
   - Why: search matches description too

6. **`test_filtered_tasks_by_repo`**
   - Input: tasks in repos "dotfiles" and "webapp"; filter = `"dotfiles"`
   - Expected: returns only dotfiles tasks
   - Why: search matches repo field

7. **`test_filtered_tasks_by_plan`**
   - Input: tasks with plans "add-auth" and "fix-bug"; filter = `"auth"`
   - Expected: returns only the add-auth task
   - Why: search matches plan field

8. **`test_filtered_tasks_case_insensitive`**
   - Input: task with title "Build CLI"; filter = `"BUILD"`
   - Expected: returns the task
   - Why: search is case-insensitive

9. **`test_filtered_tasks_by_tag`**
   - Input: task with tag "urgent"; filter = `"urgent"`
   - Expected: returns the task
   - Why: search matches tags

### Column layout

10. **`test_tasks_for_column_groups_by_status`**
    - Input: board with 2 todo, 1 in-progress, 1 done tasks (unfiltered)
    - Expected: `tasks_for_column(Status::Todo)` returns 2, `InProgress` returns 1, `Done` returns 1, others return 0
    - Why: tasks are correctly bucketed into columns

11. **`test_tasks_for_column_respects_filter`**
    - Input: board with filter `"cli"`, one matching todo, one non-matching todo
    - Expected: `tasks_for_column(Status::Todo)` returns 1
    - Why: filter applies before column grouping

12. **`test_column_order`**
    - Input: call `BoardState::column_statuses()`
    - Expected: returns `[Todo, InProgress, Done, AgentBlocked, PendingHumanResponse]`
    - Why: columns have a fixed, logical order

### Navigation

13. **`test_move_column_right`**
    - Input: board at column 0, call `move_column_right()`
    - Expected: `active_column` is 1
    - Why: right navigation works

14. **`test_move_column_right_wraps`**
    - Input: board at column 4 (last), call `move_column_right()`
    - Expected: `active_column` is 0
    - Why: wraps around

15. **`test_move_column_left`**
    - Input: board at column 1, call `move_column_left()`
    - Expected: `active_column` is 0
    - Why: left navigation works

16. **`test_move_column_left_wraps`**
    - Input: board at column 0, call `move_column_left()`
    - Expected: `active_column` is 4
    - Why: wraps around

17. **`test_move_card_down`**
    - Input: board with 3 todo tasks, selected at 0, call `move_card_down()`
    - Expected: selected card in active column is 1
    - Why: down navigation works

18. **`test_move_card_down_clamps`**
    - Input: board with 2 todo tasks, selected at 1, call `move_card_down()`
    - Expected: selected card stays at 1
    - Why: doesn't go past the end

19. **`test_move_card_up`**
    - Input: board with 3 todo tasks, selected at 2, call `move_card_up()`
    - Expected: selected card is 1
    - Why: up navigation works

20. **`test_move_card_up_clamps`**
    - Input: board at selected 0, call `move_card_up()`
    - Expected: stays at 0
    - Why: doesn't go negative

21. **`test_column_switch_resets_selection_if_out_of_bounds`**
    - Input: column 0 has 5 tasks (selected = 4), column 1 has 2 tasks. Move right.
    - Expected: active column is 1, selected card is clamped to 1 (last valid index)
    - Why: switching to a shorter column adjusts selection

### Search bar state

22. **`test_set_filter`**
    - Input: `set_filter("cli")`
    - Expected: `filter` is `"cli"`, selections are reset to 0 for all columns
    - Why: typing in search resets navigation to start

23. **`test_clear_filter`**
    - Input: set filter to `"cli"`, then `clear_filter()`
    - Expected: `filter` is empty, all tasks visible again
    - Why: Esc clears search

### Active task

24. **`test_active_task`**
    - Input: board with 2 todo tasks, column 0, selected 1
    - Expected: `active_task()` returns `Some(&tasks[1])` — the second todo task
    - Why: identifies the currently highlighted task for potential future detail view

25. **`test_active_task_empty_column`**
    - Input: board where active column has 0 tasks
    - Expected: `active_task()` returns `None`
    - Why: empty column has no active task

## Files to create

### `rust/agent-progress/src/tui/state.rs` (functional core)

```rust
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
        // If filter is empty, return all tasks.
        // Otherwise, case-insensitive substring match on title, description,
        // repo, plan, and tags.
        todo!()
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
        self.active_column = (self.active_column + 1) % 5;
        self.clamp_selection();
    }

    pub fn move_column_left(&mut self) {
        self.active_column = if self.active_column == 0 { 4 } else { self.active_column - 1 };
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

    // Helper to create a task with a given title and status
    fn task(title: &str, status: Status) -> Task {
        TaskBuilder::new(title).status(status).build().unwrap()
    }

    // All 25 tests from the Tests section above.
}
```

## Files to edit

### `rust/agent-progress/src/tui.rs`

Convert the placeholder `tui.rs` into a module directory. Replace with:

```rust
pub mod state;
```

Or rename to `tui/mod.rs` and create `tui/state.rs`.

## Acceptance criteria

- `cargo test` passes with all 25 TUI state tests green (plus all existing tests)
- `cargo clippy` has no warnings
- `BoardState` is a pure data structure — no terminal I/O, no ratatui imports
- Filtering is case-insensitive and matches title, description, repo, plan, and tags
- Navigation wraps horizontally, clamps vertically
- Column switching clamps the selected card if the new column is shorter
- `set_filter` resets all column selections to 0
- `active_task` returns the correct task or None

## Dependencies

Step 1 — needs the `Task` and `Status` domain types. Does not depend on steps 2–4.
