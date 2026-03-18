# Step 6: TUI rendering with ratatui

## Goal

Implement the terminal UI using ratatui and crossterm: a board view with status columns,
task cards, a search bar, and keyboard-driven navigation. This is the imperative shell
for the TUI — it reads from the database, builds a `BoardState`, renders it, and handles
key events.

## Background

The TUI is launched via `agent-progress tui`. It:
1. Opens a connection to the SQLite database
2. Loads all tasks into a `BoardState`
3. Enters an event loop: render → wait for key → update state → re-render
4. Exits on `q` (when search bar is not focused) or `Ctrl+c`

Layout:
```
┌─────────────────────────────────────────────────────────────────────────────┐
│  🔍 Search: [filter text here]                                             │
├──────────────┬──────────────┬──────────────┬──────────────┬────────────────┤
│  TODO (2)    │ IN-PROGRESS  │ DONE (1)     │ BLOCKED (0)  │ PENDING (0)   │
│              │   (1)        │              │              │               │
│ ┌──────────┐ │ ┌──────────┐ │ ┌──────────┐ │              │               │
│ │ Task #1  │ │ │ Task #3  │ │ │ Task #2  │ │              │               │
│ │ repo:... │ │ │ repo:... │ │ │ repo:... │ │              │               │
│ │ plan:... │ │ │ plan:... │ │ │ plan:... │ │              │               │
│ └──────────┘ │ └──────────┘ │ └──────────┘ │              │               │
│ ┌──────────┐ │              │              │              │               │
│ │ Task #4  │ │              │              │              │               │
│ │ repo:... │ │              │              │              │               │
│ └──────────┘ │              │              │              │               │
├──────────────┴──────────────┴──────────────┴──────────────┴────────────────┤
│  ←/→: columns  ↑/↓: cards  /: search  Esc: clear  q: quit                │
└─────────────────────────────────────────────────────────────────────────────┘
```

Each card shows:
- Line 1: `#<id> <title>` (truncated to column width)
- Line 2: `<repo>` (if non-empty)
- Line 3: `<plan>` (if non-empty)
- Tags as a comma-separated line (if any)

The active column has a highlighted header. The selected card in the active column has
a highlighted border.

### Key bindings
- `←` / `h`: move column left
- `→` / `l`: move column right
- `↑` / `k`: move card up
- `↓` / `j`: move card down
- `/`: focus search bar
- `Esc`: unfocus search bar / clear filter
- `q`: quit (when search is not focused)
- `Ctrl+c`: always quit
- When search is focused: typing appends to filter, `Backspace` removes last char

## Tests (write BEFORE implementation)

The rendering layer is imperative shell — it connects ratatui, crossterm, and the
database. Tests here are integration-level, but the core rendering logic can be tested
by inspecting the `ratatui::buffer::Buffer` output of widget renders.

### Card rendering tests (unit-testable via ratatui test utilities)

1. **`test_render_card_shows_id_and_title`**
   - Input: render a card widget for task id=5, title="Build CLI"
   - Expected: rendered buffer contains "#5 Build CLI"
   - Why: card displays identifying info

2. **`test_render_card_shows_repo_if_present`**
   - Input: task with repo="dotfiles"
   - Expected: rendered buffer contains "dotfiles"
   - Why: repo is shown when available

3. **`test_render_card_hides_repo_if_empty`**
   - Input: task with repo=""
   - Expected: rendered buffer does not contain a blank line for repo
   - Why: empty fields don't waste space

4. **`test_render_card_truncates_long_title`**
   - Input: task with title 50+ chars, rendered in a 20-char-wide area
   - Expected: title is truncated (with ellipsis or just cut off)
   - Why: cards must fit in columns

5. **`test_render_card_selected_has_highlight`**
   - Input: render a card with `selected=true`
   - Expected: the border style differs from `selected=false` (e.g., different color or bold)
   - Why: visual feedback for active card

### Column header tests

6. **`test_column_header_shows_status_and_count`**
   - Input: render column header for Todo with 3 tasks
   - Expected: buffer contains "TODO (3)"
   - Why: header shows status and count

7. **`test_column_header_active_has_highlight`**
   - Input: render active column header vs inactive
   - Expected: active header has distinct style
   - Why: visual feedback for active column

### Search bar tests

8. **`test_search_bar_shows_filter_text`**
   - Input: render search bar with filter "cli"
   - Expected: buffer contains "cli"
   - Why: user sees what they've typed

9. **`test_search_bar_shows_placeholder_when_empty`**
   - Input: render search bar with empty filter
   - Expected: buffer contains placeholder text like "Search..." or "/ to search"
   - Why: affordance for the search feature

### Help bar tests

10. **`test_help_bar_shows_keybindings`**
    - Input: render help bar
    - Expected: buffer contains "q: quit" and "/: search"
    - Why: keybinding hints are visible

## Files to create

### `rust/agent-progress/src/tui/render.rs` (imperative shell — ratatui rendering)

```rust
use ratatui::prelude::*;
use ratatui::widgets::*;
use crate::domain::{Status, Task};
use crate::tui::state::BoardState;

pub struct TaskCard<'a> {
    task: &'a Task,
    selected: bool,
}

impl<'a> TaskCard<'a> {
    pub fn new(task: &'a Task, selected: bool) -> Self {
        Self { task, selected }
    }
}

impl Widget for TaskCard<'_> {
    fn render(self, area: Rect, buf: &mut Buffer) {
        // Render the card: border, id+title, repo, plan, tags
        // Use highlighted border style if selected
        todo!()
    }
}

pub struct ColumnHeader {
    status: Status,
    count: usize,
    active: bool,
}

impl ColumnHeader {
    pub fn new(status: Status, count: usize, active: bool) -> Self {
        Self { status, count, active }
    }
}

impl Widget for ColumnHeader {
    fn render(self, area: Rect, buf: &mut Buffer) {
        todo!()
    }
}

pub struct SearchBar<'a> {
    filter: &'a str,
    focused: bool,
}

impl<'a> SearchBar<'a> {
    pub fn new(filter: &'a str, focused: bool) -> Self {
        Self { filter, focused }
    }
}

impl Widget for SearchBar<'_> {
    fn render(self, area: Rect, buf: &mut Buffer) {
        todo!()
    }
}

pub struct HelpBar;

impl Widget for HelpBar {
    fn render(self, area: Rect, buf: &mut Buffer) {
        todo!()
    }
}

pub fn render_board(frame: &mut Frame, state: &BoardState, search_focused: bool) {
    // Layout: search bar (top, 3 rows) | columns (middle, fill) | help bar (bottom, 1 row)
    // Split columns equally across the 5 statuses.
    // For each column: render header, then render cards.
    todo!()
}

// Column status display name helper
pub fn status_display_name(status: Status) -> &'static str {
    match status {
        Status::Todo => "TODO",
        Status::InProgress => "IN-PROGRESS",
        Status::Done => "DONE",
        Status::AgentBlocked => "BLOCKED",
        Status::PendingHumanResponse => "PENDING",
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::TaskBuilder;
    use ratatui::buffer::Buffer;
    use ratatui::layout::Rect;

    // Helper: render a widget into a buffer and return the buffer text
    fn render_to_buffer<W: Widget>(widget: W, width: u16, height: u16) -> Buffer {
        let area = Rect::new(0, 0, width, height);
        let mut buf = Buffer::empty(area);
        widget.render(area, &mut buf);
        buf
    }

    fn buffer_text(buf: &Buffer) -> String {
        let mut s = String::new();
        for y in 0..buf.area.height {
            for x in 0..buf.area.width {
                s.push(buf[(x, y)].symbol().chars().next().unwrap_or(' '));
            }
            s.push('\n');
        }
        s
    }

    // All 10 tests from the Tests section above.
}
```

### `rust/agent-progress/src/tui/app.rs` (imperative shell — event loop)

```rust
use crossterm::event::{self, Event, KeyCode, KeyModifiers};
use ratatui::prelude::*;
use rusqlite::Connection;
use crate::db::ops;
use crate::tui::state::BoardState;
use crate::tui::render;

pub fn run_tui(conn: &Connection) -> Result<(), Box<dyn std::error::Error>> {
    let tasks = ops::list_tasks(conn, &ops::TaskFilters::default())?;
    let mut state = BoardState::new(tasks);
    let mut search_focused = false;

    // Set up terminal
    crossterm::terminal::enable_raw_mode()?;
    let mut stdout = std::io::stdout();
    crossterm::execute!(stdout, crossterm::terminal::EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    loop {
        terminal.draw(|frame| render::render_board(frame, &state, search_focused))?;

        if let Event::Key(key) = event::read()? {
            if key.modifiers.contains(KeyModifiers::CONTROL) && key.code == KeyCode::Char('c') {
                break;
            }

            if search_focused {
                match key.code {
                    KeyCode::Esc => {
                        search_focused = false;
                        state.clear_filter();
                    }
                    KeyCode::Backspace => {
                        let f = state.filter().to_string();
                        if let Some(new) = f.strip_suffix(|_: char| true) {
                            state.set_filter(new);
                        }
                    }
                    KeyCode::Char(c) => {
                        let mut f = state.filter().to_string();
                        f.push(c);
                        state.set_filter(&f);
                    }
                    _ => {}
                }
            } else {
                match key.code {
                    KeyCode::Char('q') => break,
                    KeyCode::Char('/') => search_focused = true,
                    KeyCode::Left | KeyCode::Char('h') => state.move_column_left(),
                    KeyCode::Right | KeyCode::Char('l') => state.move_column_right(),
                    KeyCode::Up | KeyCode::Char('k') => state.move_card_up(),
                    KeyCode::Down | KeyCode::Char('j') => state.move_card_down(),
                    KeyCode::Esc => state.clear_filter(),
                    _ => {}
                }
            }
        }
    }

    // Restore terminal
    crossterm::terminal::disable_raw_mode()?;
    crossterm::execute!(
        terminal.backend_mut(),
        crossterm::terminal::LeaveAlternateScreen
    )?;

    Ok(())
}
```

## Files to edit

### `rust/agent-progress/src/tui/mod.rs` (or `tui.rs`)

Add the new modules:

```rust
pub mod app;
pub mod render;
pub mod state;
```

### `rust/agent-progress/src/cli.rs`

Wire the `Tui` command to `tui::app::run_tui`:

```rust
// In the run() function match:
Command::Tui => {
    let conn = Connection::open(&cli.db)?;
    db::ops::init_db(&conn)?;
    tui::app::run_tui(&conn)?;
}
```

## Acceptance criteria

- `cargo test` passes with all 10 new TUI render tests green (plus all existing tests)
- `cargo clippy` has no warnings
- `agent-progress tui` opens an interactive terminal board
- Board shows 5 columns with correct status headers and task counts
- Task cards show id, title, repo (if present), plan (if present), tags (if any)
- Arrow keys / hjkl navigate columns and cards
- `/` activates search, typing filters tasks in real time
- `Esc` clears search, `q` exits
- `Ctrl+c` always exits
- Search filters across title, description, repo, plan, and tags
- Active column and selected card have visual highlighting
- Help bar shows keybinding hints

## Dependencies

Steps 2, 4, 5 — needs the database layer (to load tasks), output format module, and the
TUI state management.
