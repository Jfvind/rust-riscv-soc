#![no_std]

use core::fmt::{self, Write};

const UART_STATUS: *const u32 = 0xF000_0000 as *const u32;
const UART_DATA: *mut u32 = 0xF000_0004 as *mut u32;
const LED_REG: *mut u32 = 0xF010_0000 as *mut u32;
const BTN_REG: *const u32 = 0xF020_0000 as *const u32;
const ADC_BASE: *const u32 = 0xF030_0000 as *const u32;
const PWM_DUTY: *mut u32 = 0xF040_0000 as *mut u32;

pub struct Uart;

impl Uart {
    pub fn new() -> Self {
        Uart
    }
}

impl Write for Uart {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for b in s.bytes() {
            unsafe {
                while (UART_STATUS.read_volatile() & 0x1) == 0 {}
                UART_DATA.write_volatile(b as u32);
            }
        }
        Ok(())
    }
}

#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => {{
        use core::fmt::Write;
        let _ = $crate::Uart::new().write_fmt(format_args!($($arg)*));
    }};
}

#[macro_export]
macro_rules! println {
    () => {
        $crate::print!("\n")
    };
    ($($arg:tt)*) => {
        $crate::print!("{}\n", format_args!($($arg)*))
    };
}

#[derive(Clone, Copy)]
#[repr(usize)]
pub enum Pmod {
    JA = 0xF050_0000,
    JB = 0xF060_0000,
    JC = 0xF070_0000,
}

impl Pmod {
    pub fn set_dir(self, mask: u8) {
        unsafe {
            (self as usize as *mut u32)
                .offset(0)
                .write_volatile(mask as u32);
        }
    }

    pub fn set_out(self, mask: u8) {
        unsafe {
            (self as usize as *mut u32)
                .offset(1)
                .write_volatile(mask as u32);
        }
    }

    pub fn read_in(self) -> u8 {
        unsafe { (self as usize as *const u32).offset(2).read_volatile() as u8 }
    }

    pub fn read_debounced(self) -> u8 {
        unsafe { (self as usize as *const u32).offset(4).read_volatile() as u8 }
    }

    pub fn set_pwm_en(self, mask: u8) {
        unsafe {
            (self as usize as *mut u32)
                .offset(3)
                .write_volatile(mask as u32);
        }
    }

    pub fn button_pressed(self, bit: u8) -> bool {
        if bit >= 8 {
            return false;
        }
        (self.read_debounced() & (1u8 << bit)) == 0
    }
}

pub fn led_write(val: u16) {
    unsafe {
        LED_REG.write_volatile(val as u32);
    }
}

pub fn btn_read() -> u8 {
    unsafe { (BTN_REG.read_volatile() & 0xF) as u8 }
}

pub fn adc_read_all() -> [u32; 4] {
    unsafe {
        [
            ADC_BASE.offset(0).read_volatile(),
            ADC_BASE.offset(1).read_volatile(),
            ADC_BASE.offset(2).read_volatile(),
            ADC_BASE.offset(3).read_volatile(),
        ]
    }
}

pub fn pwm_set_duty(channel: u8, percent: u8) {
    let percent = if percent > 100 { 100 } else { percent };
    let duty = (percent as u32 * 255) / 100;
    unsafe {
        PWM_DUTY
            .offset((channel as isize) + 1)
            .write_volatile(duty);
    }
}

pub fn rgb_set(r: u8, g: u8, b: u8) {
    pwm_set_duty(4, 100 - r);
    pwm_set_duty(5, 100 - g);
    pwm_set_duty(6, 100 - b);
}
