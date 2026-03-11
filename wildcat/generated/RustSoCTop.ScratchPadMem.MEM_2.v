module BindsTo_2_ScratchPadMem(
  input         clock,
  input         reset,
  input  [31:0] io_address, // @[\\src\\main\\scala\\wildcat\\pipeline\\ScratchPadMem.scala 13:14]
  input         io_rd, // @[\\src\\main\\scala\\wildcat\\pipeline\\ScratchPadMem.scala 13:14]
  input         io_wr, // @[\\src\\main\\scala\\wildcat\\pipeline\\ScratchPadMem.scala 13:14]
  output [31:0] io_rdData, // @[\\src\\main\\scala\\wildcat\\pipeline\\ScratchPadMem.scala 13:14]
  input  [31:0] io_wrData, // @[\\src\\main\\scala\\wildcat\\pipeline\\ScratchPadMem.scala 13:14]
  input  [3:0]  io_wrMask, // @[\\src\\main\\scala\\wildcat\\pipeline\\ScratchPadMem.scala 13:14]
  output        io_ack // @[\\src\\main\\scala\\wildcat\\pipeline\\ScratchPadMem.scala 13:14]
);

initial begin
  $readmemh("data2.hex", ScratchPadMem.MEM_2);
end
                      endmodule

bind ScratchPadMem BindsTo_2_ScratchPadMem BindsTo_2_ScratchPadMem_Inst(.*);