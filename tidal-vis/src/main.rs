mod osc;
mod state;
mod ui;

use std::io;
use std::time::Duration;

use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use crossterm::terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen};
use crossterm::ExecutableCommand;
use ratatui::backend::CrosstermBackend;
use ratatui::Terminal;

use osc::OscReceiver;
use state::AppState;

const DEFAULT_PORT: u16 = 6014;
const TICK_MS: u64 = 33; // ~30fps

fn main() -> io::Result<()> {
    let port = std::env::args()
        .nth(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(DEFAULT_PORT);

    let mut receiver = OscReceiver::new(port)?;
    let mut app_state = AppState::new();

    // Setup terminal
    enable_raw_mode()?;
    io::stdout().execute(EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(io::stdout());
    let mut terminal = Terminal::new(backend)?;

    let result = run(&mut terminal, &mut receiver, &mut app_state);

    // Restore terminal
    disable_raw_mode()?;
    io::stdout().execute(LeaveAlternateScreen)?;

    result
}

fn run(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    receiver: &mut OscReceiver,
    state: &mut AppState,
) -> io::Result<()> {
    loop {
        // Handle input
        if event::poll(Duration::from_millis(TICK_MS))? {
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press && key.code == KeyCode::Char('q') {
                    return Ok(());
                }
            }
        }

        // Process incoming OSC events
        for event in receiver.recv() {
            state.process_event(&event);
        }

        // Apply decay
        state.tick();

        // Render
        terminal.draw(|frame| ui::draw(frame, state))?;
    }
}
