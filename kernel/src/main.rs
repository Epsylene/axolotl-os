#![no_std]
#![no_main]

mod vga;

use core::panic::PanicInfo;
use vga::*;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn _start() -> ! {
    vga::WRITER.lock().clear_screen();
    vga::WRITER.lock().write_string("Hello World from the kernel!");

    loop {}
}