//---------------------------------------------------------------------
// Design  : Counter verilog top module, iCEstick (Lattice iCE40)
// Author  : Javier D. Garcia-Lasheras
//---------------------------------------------------------------------

module breadboard_top (
    input clock_i,

    inout [7:0] in_out_245,

    input rxf_245,
    output rx_245,

    input txe_245,
    output wr_245,

    output reg [7:0] leds

);

    wire clk_100M;

    wire [7:0] in_245;
    wire [7:0] out_245;
    wire tx_oe_245;

    wire [7:0] rx_si_data;
    wire rx_si_rdy;
    wire rx_si_ack;

    wire [7:0] tx_si_data;
    wire tx_si_rdy;
    wire tx_si_ack;

    //wire txe_245, wr_245;

    assign rx_si_ack = rx_si_rdy;

    always @(posedge clk_100M) begin
        if(rx_si_rdy == 1'b1) leds <= rx_si_data;
    end


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

    ft245_interface #(
        .CLOCK_PERIOD_NS(10)
    ) ft245_test (
        .rx_data_245(in_245),
        .rxf_245(rxf_245),
        .rx_245(rx_245),
        .tx_data_245(out_245),
        .txe_245(txe_245),
        .wr_245(wr_245),
        .tx_oe_245(tx_oe_245),
        .clk(clk_100M),
        .rst(1'b0),
        .rx_data_si(rx_si_data/*leds*/),
        .rx_rdy_si(rx_si_rdy), //.rx_rdy_si(),
        .rx_ack_si(rx_si_ack),  //.rx_ack_si(1'b1)
        .tx_data_si(tx_si_data),
        .tx_rdy_si(tx_si_rdy),
        .tx_ack_si(tx_si_ack)
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
    SB_IO_OD #(
        .PIN_TYPE(6'b000000),
        .NEG_TRIGGER(1'b0)
    ) OpenDrainInst0
    (
        .PACKAGEPIN (PackagePin),
        .LATCHINPUTVALUE (latchinputvalue),
        .CLOCKENABLE (clockenable),
        .INPUTCLK (inputclk),
        .OUTPUTCLK (outputclk),
        .OUTPUTENABLE (outputenable),
        .DOUT0 (dout0),
        .DOUT1 (dout1),
        .DIN0 (din0),
        .DIN1 (din1)
    );
*/
endmodule
