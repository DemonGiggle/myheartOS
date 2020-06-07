#![no_std]

#[panic_handler]
fn rust_begin_panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}
