//---------------------------------------------------------------------
// Design  : Counter verilog top module, iCEstick (Lattice iCE40)
// Author  : Javier D. Garcia-Lasheras
//---------------------------------------------------------------------

module breadboard_top (
    input clock_i,
    input rst,

    inout [7:0] in_out_245,

    input rxf_245,
    output rx_245,

    input txe_245,
    output wr_245,

    output reg [7:0] leds

);

    wire clk_100M;
    wire global_rst;

    assign global_rst = 1'b0;

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

    wire [7:0] rx_data_si;
    wire rx_rdy_si;
    wire rx_ack_si;

    wire [7:0] tx_data_si;
    wire tx_rdy_si;
    wire tx_ack_si;

    // --------------------------
    // USING FT245_BLOCK
    ft245_block #(
        .FT245_WIDTH(8),
        .CLOCK_PERIOD_NS(10)
    ) ft245_block_u (
        .clk(clk_100M),
        .rst(global_rst),

        .in_out_245(in_out_245),

        .rxf_245(rxf_245),
        .rx_245(rx_245),
        .txe_245(txe_245),
        .wr_245(wr_245),

        // simple interface
        .rx_data_si(rx_data_si),
        .rx_rdy_si(rx_rdy_si),
        .rx_ack_si(rx_ack_si),

        .tx_data_si(tx_data_si),
        .tx_rdy_si(tx_rdy_si),
        .tx_ack_si(tx_ack_si)

    );

    /*
    assign rx_ack_si = rx_rdy_si;
    always @(posedge clk_100M) begin
        if(rx_rdy_si == 1'b1) leds <= rx_data_si;
    end*/

    assign rx_ack_si = tx_ack_si;
    assign tx_rdy_si = rx_rdy_si;
    assign tx_data_si = ~rx_data_si;

    always @(posedge clk_100M) begin
        if(global_rst) begin
        end else begin
            if(rx_rdy_si == 1'b1) leds <= rx_data_si;
            //if(tx_ack_si == 1'b1 && txe_245 == 1'b0) leds <= 8'hAA;
        end
    end

endmodule
