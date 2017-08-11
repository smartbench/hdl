//---------------------------------------------------------------------
// Design  : Counter verilog top module, iCEstick (Lattice iCE40)
// Author  : Javier D. Garcia-Lasheras
//---------------------------------------------------------------------

module breadboard_top (
    input clock_i,

    input [7:0] in_245,
    input rxf_245,
    output rx_245,
    input  wr_245,
    input  

    output [7:0] leds

);
    wire clk_30M; 

    wire [7:0] data_w;
    wire rdy_w;
    wire ack_w;

    wire [7:0] rx_245_w;
    wire [7:0] tx_245_w;
    wire wr_245_w;
    wire oe_245_w;


    assign leds = data;


    // TODO for  bleeeeeee 
    SB_IO_OD OpenDrainInst0
    (
        .PACKAGEPIN (ft245_port[i]),
        .LATCHINPUTVALUE (1'b0),
        .OUTPUTENABLE (oe_245_w),
        .DOUT0 (tx_data_245[i]),
        .DIN0 (rx_data_245[i])
    );
    defparam OpenDrainInst0.PIN_TYPE = 6'b101001;

    SB_PLL40_CORE #(
            .FEEDBACK_PATH("SIMPLE"),
            .PLLOUT_SELECT("GENCLK"),
            .DIVR(4'd0),
            .DIVF(7'd63),
            .DIVQ(3'd3),
            .FILTER_RANGE(3'b001)
        )uut(
            .RESETB(1'b1),
            .BYPASS(1'b0),
            .REFERENCECLK(clock_i),
            .PLLOUTCORE(clk_30M)
        );

    ft245_interface #(
                .CLOCK_PERIOD_NS(10.0)
        ) ft245_test (    
            .clk(clk_30M),
            .rst(1'b0),

            .rx_data_245(in_245),
            .rxf_245(rxf_245),
            .rx_245(rx_245),
            
            .tx_data_245(),
            .txe_245(),
            .wr_245(wr_245_2),
            .tx_oe_245(oe_245_w),

            .tx_data_si(data),
            .tx_rdy_si(rdy_w),
            .tx_ack_si(ack_w),


            .rx_data_si(data),
            .rx_rdy_si(rdy_w),
            .rx_ack_si(ack_w)
        );


endmodule
