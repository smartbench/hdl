`timescale 1ns/1ps

// When infering RAM cascading is supported
module SB_RAM512x8 #(
  parameter ADDR_WIDTH = 10,
  parameter DATA_WIDTH = 8
)(
  input [ADDR_WIDTH-1:0] waddr,
  input [ADDR_WIDTH-1:0] raddr,
  input [DATA_WIDTH-1:0] din,
  input write_en,
  input wclk,
  input rclk,
  output reg [DATA_WIDTH-1:0] dout
);//512x8

  reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];

  always @(posedge wclk) // Write memory.
  begin
    if (write_en)
      mem[waddr] <= din; // Using write address bus.
  end

  always @(posedge wclk) // Read memory.
  begin
    dout <= mem[raddr]; // Using read address bus.
  end



`ifdef COCOTB_SIM
initial begin
  $dumpfile ("waveform.vcd");
  $dumpvars (0,SB_RAM512x8);
  #1;
end
`endif

endmodule
