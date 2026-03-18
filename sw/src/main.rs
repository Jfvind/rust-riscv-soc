#![no_std]
#![no_main]

use core::panic::PanicInfo;
use core::arch::global_asm;

// ── 1. Hardware-adresser ────────────────────────────────────
const UART_STATUS: *const u32 = 0xF000_0000 as *const u32;
const UART_DATA: *mut u32 = 0xF000_0004 as *mut u32;
const LED_REG: *mut u32 = 0xF010_0000 as *mut u32;

// ── 2. Linker symboler (Fra linker.ld) ──────────────────────────────────────
extern "C" {
    static mut __bss_start: u32;
    static mut __bss_end: u32;
}

// ── 3. Boot sekvens (Assembly) ──────────────────────────────────────────────
global_asm!(
    ".section .text._start",
    ".global _start",
    "_start:",
    "la sp, _stack_top",    // Sæt stack pointeren (defineret i linker.ld)
    "j rust_entry"          // Hop ned til Rust-miljøet
);

// ── 4. Boot sekvens (Rust) ──────────────────────────────────────────────────
#[no_mangle]
pub unsafe extern "C" fn rust_entry() -> ! {
    // Nulstil .bss for at undgå at læse SRAM støj som formentligt er der ved opstart
    let mut bss_ptr = core::ptr::addr_of_mut!(__bss_start); // Startadresse for .bss
    let bss_end = core::ptr::addr_of_mut!(__bss_end); // Slutadresse for .bss

    while bss_ptr < bss_end {
        core::ptr::write_volatile(bss_ptr, 0); // Skriv 0 til hver adresse i .bss
        bss_ptr = bss_ptr.offset(1); // næste adresse -> 4 bytes videre, da vi skriver u32
    }

    // Uploadet er styret i upload.py og linker.ld, så vi kan bare hoppe til programmet her
    main();

    loop {}
}

// ── 5. Applikationen ────────────────────────────────────────────────────────
fn main() {
    led_write(0x01);
    uart_print("PASS\n"); //Jeppes test for at se om uart virker
    led_write(0xFF);
}

// ── 6. Rå Hardware Hjælpere  ──────────────────────────────────
fn uart_putc(c: u8) { // Vent indtil UART er klar til at sende, og skriv derefter karakteren til UART-dataregistret
    unsafe {
        while (UART_STATUS.read_volatile() & 0x1) == 0 {}
        UART_DATA.write_volatile(c as u32);
    }
}

fn uart_print(s: &str) { // Skriv hver byte i strengen til UART-dataregistret ved hjælp af uart_putc
    for b in s.bytes() {
        uart_putc(b);
    }
}

fn led_write(val: u8) { // Skriv værdien til LED-registret for at styre LED'erne
    unsafe {
        LED_REG.write_volatile(val as u32);
    }
}

// ── 7. Panic Handler ────────────────────────────────────────────────────────
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! { // Hvis der opstår en panic, skriv 'E' til UART for at indikere en fejl, og bliv i en uendelig løkke
    unsafe { UART_DATA.write_volatile(b'E' as u32); }
    loop {}
}