
`timescale 1ns/1ps
module ft245_input ( 

    // ft245 rx interface
    input [7:0] in_245,
    input rxf_245,
    output reg rx_245,

    // 
    input clk,
    input rst,

    // simple interface
    output reg [7:0] data,
    output reg rdy,
    input ack
);
    
    always @(posedge clk) begin
        rx_245 <= rxf_245;
        if (rxf_245 == 1'b0) begin
            data <= in_245;
        end
    end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("waveform.vcd");
  $dumpvars (0,ft245_input);
  #1;
end
`endif

endmodule
