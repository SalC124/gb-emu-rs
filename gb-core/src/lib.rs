pub fn print_hello() -> &'static str {
    "hello"
}

#[derive(Default, Clone, Copy)]
pub struct GbInput {
    pub a: bool,
    pub b: bool,
    pub start: bool,
    pub select: bool,
    pub up: bool,
    pub down: bool,
    pub left: bool,
    pub right: bool,
}

pub struct Emulator {
    input: GbInput,
}

impl Emulator {
    pub fn new() -> Self {
        Emulator {
            input: GbInput::default()
        }
    }
}
