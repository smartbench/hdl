


`timescale 1ns/1ps

module COCO_IO #(
    parameter WIDTH = 8
)(
    inout [WIDTH-1:0] data_io,
    input oe,
    input [WIDTH-1:0] data_o,        // not an error: input of the module is the output data
    output [WIDTH-1:0] data_i

);

    assign data_io = oe ? data_o : 8'bz ; // To drive the inout net
    assign data_i = data_io;

`ifdef COCOTB_SIM
    initial begin
      $dumpfile ("waveform.vcd");
      $dumpvars (0,COCO_IO);
      #1;
    end
`endif

endmodule
