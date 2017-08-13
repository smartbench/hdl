
`timescale 1ns/1ps

`define FT245_WIDTH 8

module ft245_block #(
    parameter FT245_WIDTH = `FT245_WIDTH
)(
    //
    input clk,
    input rst,

    inout [FT245_WIDTH-1:0] in_out_245,

    input rxf_245,
    output rx_245,
    input txe_245,
    output wr_245,

    // simple interface
    output [FT245_WIDTH-1:0] rx_data_si,
    output rx_rdy_si,
    input rx_ack_si,

    input [FT245_WIDTH-1:0] tx_data_si,
    input tx_rdy_si,
    output tx_ack_si

);

    wire [7:0] in_245;
    wire [7:0] out_245;
    wire tx_oe_245;

    ft245_interface #(
        .CLOCK_PERIOD_NS(10)
    ) ft245_test (
        .clk(clk),
        .rst(1'b0),

        .rx_data_245(in_245),
        .rxf_245(rxf_245),
        .rx_245(rx_245),

        .tx_data_245(out_245),
        .txe_245(txe_245),
        .wr_245(wr_245),
        .tx_oe_245(tx_oe_245),

        .rx_data_si(rx_data_si),
        .rx_rdy_si(rx_rdy_si),
        .rx_ack_si(rx_ack_si),

        .tx_data_si(tx_data_si),
        .tx_rdy_si(tx_rdy_si),
        .tx_ack_si(tx_ack_si)
    );

    genvar h;
    generate
        for (h=0 ; h<8 ; h=h+1) begin
            SB_IO #(
                .PIN_TYPE(6'b101001),
                .PULLUP(1'b0)
            ) IO_PIN_INST (
                .PACKAGE_PIN (in_out_245[h]),
                .LATCH_INPUT_VALUE (),
                .CLOCK_ENABLE (),
                .INPUT_CLK (),
                .OUTPUT_CLK (),
                .OUTPUT_ENABLE (tx_oe_245),
                .D_OUT_0 (out_245[h]),
                .D_OUT_1 (),
                .D_IN_0 (in_245[h]),
                .D_IN_1 ()
            );
        end
    endgenerate

/*
Tri-state buffer a manopla - useful links
https://stackoverflow.com/questions/40902637/how-to-write-to-inout-port-and-read-from-inout-port-of-the-same-module
*/


`ifdef COCOTB_SIM
    initial begin
      $dumpfile ("waveform.vcd");
      $dumpvars (0,ft245_block);
      #1;
    end
`endif

endmodule
