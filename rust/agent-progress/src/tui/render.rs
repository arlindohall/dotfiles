use crate::domain::{Status, Task};
use crate::tui::state::BoardState;
use ratatui::prelude::*;
use ratatui::widgets::*;

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
        let border_style = if self.selected {
            Style::default().fg(Color::Yellow).bold()
        } else {
            Style::default()
        };

        let title_width = area.width.saturating_sub(2) as usize;
        let id_title = format!("#{} {}", self.task.id.unwrap_or(0), self.task.title);
        let id_title = truncate(&id_title, title_width);

        let mut lines: Vec<Line> = vec![Line::from(id_title)];
        if !self.task.repo.is_empty() {
            lines.push(Line::from(truncate(&self.task.repo, title_width)));
        }
        if !self.task.plan.is_empty() {
            lines.push(Line::from(truncate(&self.task.plan, title_width)));
        }
        if !self.task.tags.is_empty() {
            lines.push(Line::from(truncate(&self.task.tags.join(", "), title_width)));
        }

        let block = Block::default()
            .borders(Borders::ALL)
            .border_style(border_style);
        let paragraph = Paragraph::new(lines).block(block);
        Widget::render(paragraph, area, buf);
    }
}

pub struct ColumnHeader {
    status: Status,
    count: usize,
    active: bool,
}

impl ColumnHeader {
    pub fn new(status: Status, count: usize, active: bool) -> Self {
        Self {
            status,
            count,
            active,
        }
    }
}

impl Widget for ColumnHeader {
    fn render(self, area: Rect, buf: &mut Buffer) {
        let text = format!("{} ({})", status_display_name(self.status), self.count);
        let style = if self.active {
            Style::default().fg(Color::Yellow).bold()
        } else {
            Style::default()
        };
        let para = Paragraph::new(text)
            .style(style)
            .alignment(Alignment::Center)
            .block(Block::default().borders(Borders::BOTTOM));
        Widget::render(para, area, buf);
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
        let content = if self.filter.is_empty() {
            "/ to search".to_string()
        } else {
            self.filter.to_string()
        };
        let border_style = if self.focused {
            Style::default().fg(Color::Yellow)
        } else {
            Style::default()
        };
        let para = Paragraph::new(content)
            .block(
                Block::default()
                    .title("🔍 Search")
                    .borders(Borders::ALL)
                    .border_style(border_style),
            );
        Widget::render(para, area, buf);
    }
}

pub struct HelpBar;

impl Widget for HelpBar {
    fn render(self, area: Rect, buf: &mut Buffer) {
        let text = "←/→: columns  ↑/↓: cards  /: search  Esc: clear  q: quit";
        let para = Paragraph::new(text).style(Style::default().fg(Color::DarkGray));
        Widget::render(para, area, buf);
    }
}

pub fn render_board(frame: &mut Frame, state: &BoardState, search_focused: bool) {
    let area = frame.area();

    let layout = Layout::vertical([
        Constraint::Length(3),
        Constraint::Fill(1),
        Constraint::Length(1),
    ])
    .split(area);

    let search_area = layout[0];
    let board_area = layout[1];
    let help_area = layout[2];

    frame.render_widget(SearchBar::new(state.filter(), search_focused), search_area);
    frame.render_widget(HelpBar, help_area);

    let column_constraints = [Constraint::Ratio(1, 5); 5];
    let column_areas = Layout::horizontal(column_constraints).split(board_area);

    let statuses = BoardState::column_statuses();
    for (i, &status) in statuses.iter().enumerate() {
        let col_area = column_areas[i];
        let tasks = state.tasks_for_column(status);
        let is_active = state.active_column() == i;

        let header_area = Rect::new(col_area.x, col_area.y, col_area.width, 2);
        let cards_area = Rect::new(
            col_area.x,
            col_area.y + 2,
            col_area.width,
            col_area.height.saturating_sub(2),
        );

        frame.render_widget(ColumnHeader::new(status, tasks.len(), is_active), header_area);

        let card_height = 5u16;
        for (j, task) in tasks.iter().enumerate() {
            let y = cards_area.y + (j as u16) * card_height;
            if y + card_height > cards_area.y + cards_area.height {
                break;
            }
            let card_area = Rect::new(cards_area.x, y, cards_area.width, card_height);
            let selected = is_active && state.selected_card() == j;
            frame.render_widget(TaskCard::new(task, selected), card_area);
        }
    }
}

pub fn status_display_name(status: Status) -> &'static str {
    match status {
        Status::Todo => "TODO",
        Status::InProgress => "IN-PROGRESS",
        Status::Done => "DONE",
        Status::AgentBlocked => "BLOCKED",
        Status::PendingHumanResponse => "PENDING",
    }
}

fn truncate(s: &str, max_chars: usize) -> String {
    if s.chars().count() <= max_chars {
        s.to_string()
    } else {
        let mut out: String = s.chars().take(max_chars.saturating_sub(1)).collect();
        out.push('…');
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::TaskBuilder;
    use ratatui::buffer::Buffer;
    use ratatui::layout::Rect;

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

    fn make_task(id: i64, title: &str) -> Task {
        TaskBuilder::new(title).id(id).build().unwrap()
    }

    #[test]
    fn test_render_card_shows_id_and_title() {
        let task = make_task(5, "Build CLI");
        let buf = render_to_buffer(TaskCard::new(&task, false), 30, 5);
        let text = buffer_text(&buf);
        assert!(text.contains("#5 Build CLI"), "expected '#5 Build CLI' in:\n{text}");
    }

    #[test]
    fn test_render_card_shows_repo_if_present() {
        let task = TaskBuilder::new("Task").id(1).repo("dotfiles").build().unwrap();
        let buf = render_to_buffer(TaskCard::new(&task, false), 30, 5);
        let text = buffer_text(&buf);
        assert!(text.contains("dotfiles"), "expected 'dotfiles' in:\n{text}");
    }

    #[test]
    fn test_render_card_hides_repo_if_empty() {
        let task = make_task(1, "No repo task");
        let buf = render_to_buffer(TaskCard::new(&task, false), 30, 5);
        let text = buffer_text(&buf);
        let non_border_lines: Vec<&str> = text
            .lines()
            .filter(|l| !l.trim_matches(['│', '┌', '┐', '└', '┘', '─', ' ']).is_empty())
            .collect();
        assert_eq!(non_border_lines.len(), 1, "should only have 1 content line (title), got: {non_border_lines:?}");
    }

    #[test]
    fn test_render_card_truncates_long_title() {
        let long_title = "A".repeat(60);
        let task = make_task(1, &long_title);
        let buf = render_to_buffer(TaskCard::new(&task, false), 20, 5);
        let text = buffer_text(&buf);
        for line in text.lines() {
            assert!(
                line.chars().count() <= 20,
                "line exceeds width 20: {line:?}"
            );
        }
    }

    #[test]
    fn test_render_card_selected_has_highlight() {
        let task = make_task(1, "My task");
        let selected_buf = render_to_buffer(TaskCard::new(&task, true), 30, 5);
        let unselected_buf = render_to_buffer(TaskCard::new(&task, false), 30, 5);
        let mut differs = false;
        for y in 0..5 {
            for x in 0..30 {
                if selected_buf[(x, y)].style() != unselected_buf[(x, y)].style() {
                    differs = true;
                }
            }
        }
        assert!(differs, "selected and unselected cards should have different styles");
    }

    #[test]
    fn test_column_header_shows_status_and_count() {
        let buf = render_to_buffer(ColumnHeader::new(Status::Todo, 3, false), 20, 2);
        let text = buffer_text(&buf);
        assert!(text.contains("TODO"), "expected 'TODO' in:\n{text}");
        assert!(text.contains("3"), "expected count '3' in:\n{text}");
    }

    #[test]
    fn test_column_header_active_has_highlight() {
        let active_buf = render_to_buffer(ColumnHeader::new(Status::Todo, 0, true), 20, 2);
        let inactive_buf = render_to_buffer(ColumnHeader::new(Status::Todo, 0, false), 20, 2);
        let mut differs = false;
        for y in 0..2 {
            for x in 0..20 {
                if active_buf[(x, y)].style() != inactive_buf[(x, y)].style() {
                    differs = true;
                }
            }
        }
        assert!(differs, "active and inactive column headers should have different styles");
    }

    #[test]
    fn test_search_bar_shows_filter_text() {
        let buf = render_to_buffer(SearchBar::new("cli", false), 30, 3);
        let text = buffer_text(&buf);
        assert!(text.contains("cli"), "expected 'cli' in:\n{text}");
    }

    #[test]
    fn test_search_bar_shows_placeholder_when_empty() {
        let buf = render_to_buffer(SearchBar::new("", false), 30, 3);
        let text = buffer_text(&buf);
        assert!(
            text.contains("/ to search") || text.contains("Search"),
            "expected placeholder in:\n{text}"
        );
    }

    #[test]
    fn test_help_bar_shows_keybindings() {
        let buf = render_to_buffer(HelpBar, 80, 1);
        let text = buffer_text(&buf);
        assert!(text.contains("q: quit"), "expected 'q: quit' in:\n{text}");
        assert!(text.contains("/: search"), "expected '/: search' in:\n{text}");
    }
}
