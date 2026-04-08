package rvsoc

import chisel3._
import chisel3.util._

// 1. The BlackBox: Tells Chisel about the Xilinx XADC IP
// We assume you generate a standard XADC wizard IP in Vivado named "xadc_wiz_0"
class xadc_wiz_0 extends BlackBox {
  val io = IO(new Bundle {
    val dclk_in         = Input(Clock())
    val reset_in        = Input(Bool())
    
    // Analog input pins (Basys3 JXADC header)
    val vauxp6          = Input(Bool()) 
    val vauxn6          = Input(Bool())
    
    // Dynamic Reconfiguration Port (DRP) to read data
    val daddr_in        = Input(UInt(7.W))
    val den_in          = Input(Bool())
    val di_in           = Input(UInt(16.W))
    val dwe_in          = Input(Bool())
    val do_out          = Output(UInt(16.W))
    val drdy_out        = Output(Bool())
    
    // Status
    val eoc_out         = Output(Bool()) // End Of Conversion
    val vp_in           = Input(Bool())
    val vn_in           = Input(Bool())
  })
}

// 2. The Chisel Controller: Fetches data via the DRP and exposes it to Rust
class AdcController extends Module {
  val io = IO(new Bundle {
    val vauxp6  = Input(Bool())
    val vauxn6  = Input(Bool())
    val adcData = Output(UInt(16.W))
  })

  // Instantiate the BlackBox
  val xadc = Module(new xadc_wiz_0())
  
  // Wire up clocks and static defaults
  xadc.io.dclk_in  := clock
  xadc.io.reset_in := reset.asBool
  xadc.io.vauxp6   := io.vauxp6
  xadc.io.vauxn6   := io.vauxn6
  xadc.io.vp_in    := false.B
  xadc.io.vn_in    := false.B
  
  // We want to read VAUX6. In Xilinx XADC, VAUX6 data is stored at DRP address 0x16
  xadc.io.daddr_in := "h16".U(7.W)
  xadc.io.di_in    := 0.U
  xadc.io.dwe_in   := false.B // Read only, never write

  // State Machine for DRP Bus
  val idle :: waitReady :: Nil = Enum(2)
  val state = RegInit(idle)
  val dataReg = RegInit(0.U(16.W))

  xadc.io.den_in := false.B // Default: don't request read

  switch(state) {
    is(idle) {
      // eoc_out pulses high when a new analog sample has been digitized
      when(xadc.io.eoc_out) { 
        xadc.io.den_in := true.B // Enable DRP read
        state := waitReady
      }
    }
    is(waitReady) {
      // drdy_out pulses high when the DRP spits out the data
      when(xadc.io.drdy_out) {
        dataReg := xadc.io.do_out // Capture the 16-bit analog value
        state := idle
      }
    }
  }

  // Only the upper 12 bits of the XADC output contain the actual analog data.
  // We shift it right by 4 so it's a clean 0 to 4095 value for the Rust code.
  io.adcData := dataReg >> 4 
}