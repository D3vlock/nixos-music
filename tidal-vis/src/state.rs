use std::collections::HashMap;
use std::time::Instant;

use crate::osc::DirtEvent;

pub const NUM_COLUMNS: usize = 16;
const DECAY_FACTOR: f64 = 0.92;
const IDLE_TIMEOUT_SECS: f64 = 5.0;

pub struct OrbitState {
    pub columns: [f64; NUM_COLUMNS],
    pub last_event: Instant,
    pub last_sample: String,
}

impl OrbitState {
    fn new() -> Self {
        Self {
            columns: [0.0; NUM_COLUMNS],
            last_event: Instant::now(),
            last_sample: String::new(),
        }
    }

    fn hit(&mut self, column: usize, sample: &str) {
        if column < NUM_COLUMNS {
            self.columns[column] = 1.0;
        }
        self.last_event = Instant::now();
        self.last_sample = sample.to_string();
    }

    fn decay(&mut self) {
        for col in &mut self.columns {
            *col *= DECAY_FACTOR;
            if *col < 0.01 {
                *col = 0.0;
            }
        }
    }

    pub fn is_idle(&self) -> bool {
        self.last_event.elapsed().as_secs_f64() > IDLE_TIMEOUT_SECS
    }
}

pub struct AppState {
    pub orbits: HashMap<u8, OrbitState>,
}

impl AppState {
    pub fn new() -> Self {
        Self {
            orbits: HashMap::new(),
        }
    }

    pub fn process_event(&mut self, event: &DirtEvent) {
        let orbit = self.orbits.entry(event.orbit).or_insert_with(OrbitState::new);
        let column = event_to_column(event);
        orbit.hit(column, &event.sample);
    }

    pub fn tick(&mut self) {
        for orbit in self.orbits.values_mut() {
            orbit.decay();
        }
    }

    pub fn active_orbits(&self) -> Vec<u8> {
        let mut keys: Vec<u8> = self
            .orbits
            .keys()
            .filter(|k| !self.orbits[k].is_idle())
            .copied()
            .collect();
        keys.sort();
        keys
    }
}

fn event_to_column(event: &DirtEvent) -> usize {
    if let Some(note) = event.note {
        let n = note.round() as i32;
        ((n % NUM_COLUMNS as i32 + NUM_COLUMNS as i32) % NUM_COLUMNS as i32) as usize
    } else {
        // Hash sample name to get a column
        let hash: usize = event
            .sample
            .bytes()
            .fold(0usize, |acc, b| acc.wrapping_mul(31).wrapping_add(b as usize));
        hash % NUM_COLUMNS
    }
}
