use ratatui::layout::{Constraint, Layout};
use ratatui::style::{Color, Style};
use ratatui::text::{Line, Span};
use ratatui::Frame;

use crate::state::{AppState, NUM_COLUMNS};

const BLOCKS: &[char] = &[' ', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];

const ORBIT_COLORS: &[Color] = &[
    Color::Cyan,
    Color::Magenta,
    Color::Yellow,
    Color::Green,
    Color::Red,
    Color::Blue,
    Color::LightCyan,
    Color::LightMagenta,
];

fn value_to_block(v: f64) -> char {
    let idx = (v * (BLOCKS.len() - 1) as f64).round() as usize;
    BLOCKS[idx.min(BLOCKS.len() - 1)]
}

fn orbit_color(orbit: u8) -> Color {
    ORBIT_COLORS[orbit as usize % ORBIT_COLORS.len()]
}

pub fn draw(frame: &mut Frame, state: &AppState) {
    let area = frame.area();
    let active = state.active_orbits();

    if active.is_empty() {
        let line = Line::from(Span::styled(
            "  waiting for tidal events...",
            Style::default().fg(Color::DarkGray),
        ));
        frame.render_widget(line, area);
        return;
    }

    let constraints: Vec<Constraint> = active
        .iter()
        .map(|_| Constraint::Length(2))
        .chain(std::iter::once(Constraint::Min(0)))
        .collect();

    let rows = Layout::vertical(constraints).split(area);

    for (i, &orbit_id) in active.iter().enumerate() {
        if i >= rows.len() - 1 {
            break;
        }

        let orbit = &state.orbits[&orbit_id];
        let color = orbit_color(orbit_id);
        let label = format!(" d{} ", orbit_id + 1);

        // First line: label + bars
        let mut spans = vec![Span::styled(
            label,
            Style::default().fg(Color::White).bg(color),
        )];

        spans.push(Span::raw(" "));

        for col_idx in 0..NUM_COLUMNS {
            let v = orbit.columns[col_idx];
            let block = value_to_block(v);
            let intensity = if v > 0.7 {
                color
            } else if v > 0.3 {
                dim_color(color)
            } else if v > 0.0 {
                Color::DarkGray
            } else {
                Color::Indexed(236) // very dark gray
            };
            spans.push(Span::styled(
                format!("{block} "),
                Style::default().fg(intensity),
            ));
        }

        // Sample name
        if !orbit.last_sample.is_empty() {
            spans.push(Span::styled(
                format!(" {}", orbit.last_sample),
                Style::default().fg(Color::DarkGray),
            ));
        }

        let line = Line::from(spans);
        frame.render_widget(line, rows[i]);
    }
}

fn dim_color(color: Color) -> Color {
    match color {
        Color::Cyan => Color::Indexed(37),
        Color::Magenta => Color::Indexed(133),
        Color::Yellow => Color::Indexed(179),
        Color::Green => Color::Indexed(71),
        Color::Red => Color::Indexed(167),
        Color::Blue => Color::Indexed(67),
        Color::LightCyan => Color::Indexed(80),
        Color::LightMagenta => Color::Indexed(176),
        other => other,
    }
}
