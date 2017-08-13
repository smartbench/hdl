//---------------------------------------------------------------------
// Design  : Counter verilog top module, iCEstick (Lattice iCE40)
// Author  : Javier D. Garcia-Lasheras
//---------------------------------------------------------------------

module breadboard_top (
    input clock_i,

    input [7:0] in_245,
    input rxf_245,
    output rx_245,

    output [7:0] leds

);
    wire clk_30M;
    /* assign leds[0] = rxf_245; */
    /* assign leds[1] = rx_245; */

    wire clk_100M;
    // PLL instantiation
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0000),
        .DIVF(7'b1000010),
        .DIVQ(3'b011),
        .FILTER_RANGE(3'b001)
    )uut(
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clock_i),
        .PLLOUTCORE(clk_100M)
    );

    wire rx_rdy_si;
    ft245_interface #(
            .CLOCK_PERIOD_NS(10)
        ) ft245_test (
            .rx_data_245(in_245),
            .rxf_245(rxf_245),
            .rx_245(rx_245),
            .tx_data_245(),
            .txe_245(),
            .wr_245(),
            .tx_oe_245(),
            .clk(clk_100M),
            .rst(1'b0),
            .rx_data_si(leds),
            .rx_rdy_si(rx_rdy_si), //.rx_rdy_si(),
            .rx_ack_si(rx_rdy_si)  //.rx_ack_si(1'b1)
        );


endmodule
