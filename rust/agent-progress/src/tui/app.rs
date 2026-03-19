use crate::db::ops;
use crate::tui::render;
use crate::tui::state::BoardState;
use crossterm::event::{self, Event, KeyCode, KeyModifiers};
use ratatui::prelude::*;
use rusqlite::Connection;

pub fn run_tui(conn: &Connection) -> Result<(), Box<dyn std::error::Error>> {
    let tasks = ops::list_tasks(conn, &ops::TaskFilters::default())?;
    let mut state = BoardState::new(tasks);
    let mut search_focused = false;

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
                        let new: String = f.chars().take(f.chars().count().saturating_sub(1)).collect();
                        state.set_filter(&new);
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

    crossterm::terminal::disable_raw_mode()?;
    crossterm::execute!(
        terminal.backend_mut(),
        crossterm::terminal::LeaveAlternateScreen
    )?;

    Ok(())
}
