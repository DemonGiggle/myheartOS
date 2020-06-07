#![no_std]

#[panic_handler]
fn rust_begin_panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn kmain() -> ! {
    unsafe {
        // Output OKAY on screen
        let vga = 0xb8000 as *mut u64;
        *vga = 0x2f592f412f4b2f4f;
    };

    loop {}
}
