use mcu_hal::{adc_read_all, btn_read, led_write, rgb_set, Pmod};

pub fn main() -> ! {
    mcu_hal::println!("=== DTU MCU Booted ===");
    mcu_hal::println!("SRAM Size: {} bytes", 4096);
    mcu_hal::println!("Status: PASS");

    Pmod::JA.set_dir(0b0111_0111);
    Pmod::JA.set_pwm_en(0b_0111_0000);

    let mut fade: u8 = 0;
    let mut fade_up = true;
    let mut color_phase: u8 = 0;

    loop {
        let adc_val = adc_read_all();
        let btn_val = btn_read();

        let mut adc_leds: u16 = 0;
        if adc_val[0] > 256 {
            adc_leds |= 0b1000_0000_0000_0000;
        }
        if adc_val[0] > 512 {
            adc_leds |= 0b1100_0000_0000_0000;
        }
        if adc_val[0] > 768 {
            adc_leds |= 0b1110_0000_0000_0000;
        }
        if adc_val[0] > 1024 {
            adc_leds |= 0b1111_0000_0000_0000;
        }
        if adc_val[0] > 1280 {
            adc_leds |= 0b1111_1000_0000_0000;
        }
        if adc_val[0] > 1536 {
            adc_leds |= 0b1111_1100_0000_0000;
        }
        if adc_val[0] > 1792 {
            adc_leds |= 0b1111_1110_0000_0000;
        }
        if adc_val[0] > 2048 {
            adc_leds |= 0b1111_1111_0000_0000;
        }
        if adc_val[0] > 2304 {
            adc_leds |= 0b1111_1111_1000_0000;
        }
        if adc_val[0] > 2560 {
            adc_leds |= 0b1111_1111_1100_0000;
        }
        if adc_val[0] > 2816 {
            adc_leds |= 0b1111_1111_1110_0000;
        }
        if adc_val[0] > 3072 {
            adc_leds |= 0b1111_1111_1111_0000;
        }
        if adc_val[0] > 3328 {
            adc_leds |= 0b1111_1111_1111_1000;
        }
        if adc_val[0] > 3584 {
            adc_leds |= 0b1111_1111_1111_1100;
        }
        if adc_val[0] > 3840 {
            adc_leds |= 0b1111_1111_1111_1110;
        }
        led_write(adc_leds);

        Pmod::JA.set_out(btn_val);

        match color_phase {
            0 => rgb_set(fade, 0, 0),
            1 => rgb_set(0, fade, 0),
            _ => rgb_set(0, 0, fade),
        }

        if fade_up {
            if fade >= 100 {
                fade_up = false;
            } else {
                fade += 1;
            }
        } else if fade == 0 {
            fade_up = true;
            color_phase = (color_phase + 1) % 3;
        } else {
            fade -= 1;
        }

        for _ in 0..150_000 {
            unsafe { core::arch::asm!("nop") };
        }
    }
}
