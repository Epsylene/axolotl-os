#![no_std]
#![no_main]

use core::panic::PanicInfo;

// Todo

#[panic_handler]
#[no_mangle]
pub fn panic(info: &PanicInfo) -> ! {
    loop {}
}