use rosc::{OscMessage, OscPacket, OscType};
use std::net::UdpSocket;

pub struct DirtEvent {
    pub orbit: u8,
    pub sample: String,
    pub note: Option<f32>,
}

fn parse_dirt_play(msg: &OscMessage) -> Option<DirtEvent> {
    if msg.addr != "/dirt/play" {
        return None;
    }

    let args = &msg.args;
    let mut orbit: u8 = 0;
    let mut sample = String::new();
    let mut note: Option<f32> = None;

    // TidalCycles sends flat key-value pairs: [key, value, key, value, ...]
    let mut i = 0;
    while i + 1 < args.len() {
        if let OscType::String(ref key) = args[i] {
            match key.as_str() {
                "orbit" => {
                    if let Some(v) = extract_int(&args[i + 1]) {
                        orbit = v as u8;
                    }
                }
                "s" => {
                    if let OscType::String(ref v) = args[i + 1] {
                        sample = v.clone();
                    }
                }
                "note" | "n" => {
                    if let Some(v) = extract_float(&args[i + 1]) {
                        note = Some(v);
                    }
                }
                _ => {}
            }
            i += 2;
        } else {
            i += 1;
        }
    }

    if sample.is_empty() {
        return None;
    }

    Some(DirtEvent {
        orbit,
        sample,
        note,
    })
}

fn extract_int(arg: &OscType) -> Option<i32> {
    match arg {
        OscType::Int(v) => Some(*v),
        OscType::Float(v) => Some(*v as i32),
        OscType::Double(v) => Some(*v as i32),
        _ => None,
    }
}

fn extract_float(arg: &OscType) -> Option<f32> {
    match arg {
        OscType::Float(v) => Some(*v),
        OscType::Double(v) => Some(*v as f32),
        OscType::Int(v) => Some(*v as f32),
        _ => None,
    }
}

fn process_packet(packet: OscPacket, events: &mut Vec<DirtEvent>) {
    match packet {
        OscPacket::Message(msg) => {
            if let Some(event) = parse_dirt_play(&msg) {
                events.push(event);
            }
        }
        OscPacket::Bundle(bundle) => {
            for p in bundle.content {
                process_packet(p, events);
            }
        }
    }
}

pub struct OscReceiver {
    socket: UdpSocket,
    buf: [u8; 4096],
}

impl OscReceiver {
    pub fn new(port: u16) -> std::io::Result<Self> {
        let socket = UdpSocket::bind(format!("127.0.0.1:{}", port))?;
        socket.set_nonblocking(true)?;
        Ok(Self {
            socket,
            buf: [0u8; 4096],
        })
    }

    pub fn recv(&mut self) -> Vec<DirtEvent> {
        let mut events = Vec::new();
        loop {
            match self.socket.recv(&mut self.buf) {
                Ok(size) => {
                    if let Ok((_, packet)) = rosc::decoder::decode_udp(&self.buf[..size]) {
                        process_packet(packet, &mut events);
                    }
                }
                Err(_) => break,
            }
        }
        events
    }
}
