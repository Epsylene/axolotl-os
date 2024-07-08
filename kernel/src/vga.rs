use lazy_static::lazy_static;
use spin::Mutex;

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

impl ScreenChar {
    pub fn new(ascii_character: u8, color_code: ColorCode) -> ScreenChar {
        ScreenChar {
            ascii_character,
            color_code,
        }
    }
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

// We want to have a global instance of the Writer struct
// instead of carrying it around, so we declare a static
// variable; however, because some of the expressions are not
// const-evaluable, we have to use the `lazy_static` crate to
// delay the initialization of the variable until runtime. This
// makes the Writer inmutable, however; we need a type that
// provides interior mutability--so that we can change the
// individual VGA cells--, but in a thread-safe way. We can't
// use mutexes, since the kernel does not have blocking
// support, but we can use spinlocks: these are locks that
// cause any thread trying to acquire a resource to simply wait
// in a loop ("spin") while repeatedly checking whether the
// lock is available. In general multi-threaded contexts, this
// is not efficient since the spinning threads are wasting CPU
// cycles, but they avoid the overhead from OS rescheduling or
// context switching, so they are useful if threads are likely
// to be blocked for only short periods. The `spin` crate
// provides a no_std implementation of spinlocks, allowing us
// to safely mutate the Writer instance.
lazy_static! {
    pub static ref WRITER: Mutex<Writer> = Mutex::new(Writer {
        column_position: 0,
        color_code: ColorCode::new(Color::LightGreen, Color::Black),
        buffer: unsafe { &mut *(0xb8000 as *mut Buffer) },
    });
}

impl Writer {
    pub fn write_byte(&mut self, byte: u8) {
        match byte {
            // Newline character
            b'\n' => self.new_line(),
            // Printable ASCII byte
            byte => {
                // If we are at the end of the line (after the
                // 80th column), print a new line and start at
                // the first column of the next row.
                if self.column_position >= BUFFER_WIDTH {
                    self.new_line();
                }

                // Printing starts at the bottom left corner of
                // the screen, so we just need to set the row
                // to the height of the buffer minus one.
                let row = BUFFER_HEIGHT - 1;
                let col = self.column_position;

                // Then update the cell and the column position
                // for the current character.
                let color = self.color_code;
                unsafe {
                    // When dealing with MMIO, a problem can
                    // arise when reading or writing to a
                    // memory location. Say we are watching the
                    // value at a certain address in a loop,
                    // waiting for it to be changed by
                    // hardware. Because there is no code
                    // actually using the pointer, the compiler
                    // might optimize the loop away. Marking
                    // this kind of access as "volatile" tells
                    // the compiler that there might be side
                    // effects outside the scope of the
                    // program, so we can't skip the memory
                    // read or write operation.
                    core::ptr::write_volatile(
                        &mut self.buffer.chars[row][col],
                        ScreenChar::new(byte, color)
                    )
                };
                // self.buffer.chars[row][col] ScreenChar {
                //     ascii_character: byte,
                //     color_code,
                // });
                self.column_position += 1;
            }
        }
    }

    pub fn write_string(&mut self, s: &str) {
        for byte in s.bytes() {
            match byte {
                // Printable ASCII byte--anything between a
                // space (0x20) and a tilde (~ 0x7e) in page
                // 437, basically--or a newline.
                0x20..=0x7e | b'\n' => self.write_byte(byte),
                // Other characters are not considered to be
                // part of the printable ASCII range, so we
                // output a filled square (■ 0xfe) character
                // instead. Note that this also works for UTF-8
                // characters, since multi-byte code points are
                // guaranteed to not have individual bytes in
                // the ASCII range.
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
        // A blank is just a space with the same color code as
        // the rest of characters.
        let blank = ScreenChar::new(b' ', self.color_code);

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