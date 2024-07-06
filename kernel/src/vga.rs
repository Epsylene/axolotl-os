// The VGA text mode was introduced by IBM in 1987 to print
// characters to the screen, by writing to a special region of
// memory, the VGA buffer. This is a 2D array, of tipically
// 25x80 cells, which is directly rendered to the screen; each
// cell is 2 bytes long, such that:
//  - Bits 0-7 encode the page 437 (an extended ASCII set) code
// point;
//  - Bits 8-11 the foreground color of the character; 
//  - Bits 12-14 its background color; 
//  - Bit 15 either a fourth background bit or a flag to set
// blinking.
//
// The VGA buffer is located at the physical address 0xb8000,
// and uses memory-mapped I/O (MMIO), a method which uses the
// same address space for both memory and I/O devices. This
// means that writing to the VGA buffer is equivalent to
// writing to the screen.

// There is a total of 16 different color, that come from the
// combination of 8 base colors from the first 3 bits with a
// 4th "bright" bit (for example, 0000 for black and 1000 for
// dark gray, 0001 for blue and 1001 for light blue, etc). The
// repr(u8) attribute tells the compiler to represent the
// internal fields as u8 values, since the layout is not
// guaranteed by Rust by default.
#[repr(u8)]
pub enum Color {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    Pink = 13,
    Yellow = 14,
    White = 15,
}

// A color code is a u8 (the first byte of the VGA cell) that
// we construct from the combination of a foreground and
// background color. The repr(transparent) attribute ensures
// that it has the same repr as its single field (effectively,
// that no padding will be added, so we can safely say that a
// ColorCode is a u8 in memory).
#[repr(transparent)]
#[derive(Clone, Copy)]
pub struct ColorCode(u8);

impl ColorCode {
    pub fn new(foreground: Color, background: Color) -> ColorCode {
        // The low 4 bits are the background color, and the
        // high 4 bits are the foreground color.
        ColorCode((background as u8) << 4 | (foreground as u8))
    }
}

// A character on the screen is then the combination of an
// (extended) ASCII character and a color code. Field ordering
// in structs is undefined in Rust, so we use the repr(C)
// attribute to ensure that they are laid out exactly like a C
// struct, since the VGA cells are expected to have a character
// in the first byte and a color in the second.
#[repr(C)]
#[derive(Clone, Copy)]
struct ScreenChar {
    ascii_character: u8,
    color_code: ColorCode,
}

const BUFFER_HEIGHT: usize = 25;
const BUFFER_WIDTH: usize = 80;

// And the VGA buffer is a 2D array of ScreenChars.
pub struct Buffer {
    chars: [[ScreenChar; BUFFER_WIDTH]; BUFFER_HEIGHT],
}

pub struct Writer {
    pub column_position: usize,
    pub color_code: ColorCode,
    pub buffer: &'static mut Buffer,
}

impl Writer {
    pub fn write_byte(&mut self, byte: u8) {
        match byte {
            // Newline character
            b'\n' => self.new_line(),
            // Printable ASCII byte
            byte => {
                // If we are at the end of the line (after the
                // 80th column), go to the next line
                if self.column_position >= BUFFER_WIDTH {
                    self.new_line();
                }

                let row = BUFFER_HEIGHT - 1;
                let col = self.column_position;

                let color_code = self.color_code;
                self.buffer.chars[row][col] = ScreenChar {
                    ascii_character: byte,
                    color_code,
                };
                self.column_position += 1;
            }
        }
    }

    pub fn write_string(&mut self, s: &str) {
        for byte in s.bytes() {
            match byte {
                // Printable ASCII byte--anything between a
                // space (0x20) and a tilde (~ 0x7e),
                // basically--or a newline.
                0x20..=0x7e | b'\n' => self.write_byte(byte),
                // Not part of the printable ASCII range, so we
                // output a filled square (■ 0xfe) character
                // instead.
                _ => self.write_byte(0xfe),
            }
        }
    }

    fn new_line(&mut self) {
        // Shift all lines one up
        for row in 1..BUFFER_HEIGHT {
            for col in 0..BUFFER_WIDTH {
                let character = self.buffer.chars[row][col];
                self.buffer.chars[row - 1][col] = character;
            }
        }
        // Clear the last line
        self.clear_row(BUFFER_HEIGHT - 1);
        self.column_position = 0;
    }

    fn clear_row(&mut self, row: usize) {
        let blank = ScreenChar {
            ascii_character: b' ',
            color_code: self.color_code,
        };
        for col in 0..BUFFER_WIDTH {
            self.buffer.chars[row][col] = blank;
        }
    }

    pub fn clear_screen(&mut self) {
        for row in 0..BUFFER_HEIGHT {
            self.clear_row(row);
        }
    }
}