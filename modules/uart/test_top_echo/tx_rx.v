/*
    Isolating USB Communication.
*/


`timescale 1ns/1ps

`define WIDTH 8
//`define BAUDRATE 921600
`define F_CLK 99000000
`define BAUDRATE 9600

module tx_rx (
    input clk_i,
    input rst_i,

    // uart interface
    input rx,
    output tx,

    output reg [7:0] leds = 0
);

    // PLL output clock
    wire clk_100M;

    // FT245 SI
    wire [`WIDTH-1:0]   si_ft245_rx_data;
    wire                si_ft245_rx_rdy;
    wire                si_ft245_rx_ack;

    wire [`WIDTH-1:0]   si_ft245_tx_data;
    wire                si_ft245_tx_rdy;
    wire                si_ft245_tx_ack;

    reg start=0;
    reg [15:0] rst_cnt = 0;
    wire rst;

    assign si_ft245_tx_data = si_ft245_rx_data;
    assign si_ft245_tx_rdy = si_ft245_rx_rdy;
    assign si_ft245_rx_ack = si_ft245_tx_ack;

    // initial reset
    assign rst = ~start | rst_i;

    always @(posedge clk_100M) begin
        rst_cnt <= rst_cnt + 1;
        if(rst_cnt == 1000) start <= 1;
    end

    //reg [31:0] ledCounter = 0;
    //localparam [31:0] aa = 32'd99000000;
    always @(posedge clk_100M) begin
        if(rst) leds <= 8'h81;
        //if(rx==1'b0) leds <= 8'h55;
        /*ledCounter <= ledCounter + 1;
        if(ledCounter == aa) begin
            ledCounter <= 0;
            leds <= leds + 1;
        end*/
        if(si_ft245_rx_rdy) begin
            leds <= si_ft245_rx_data;
        end
    end

    // PLL instantiation
    // Input 12 MHz
    // Output 99 MHz
    // Fo = Fi * (DIVF+1) / [ 2^DIVQ * (DIVR+1) ]
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
        .REFERENCECLK(clk_i),
        .PLLOUTCORE(clk_100M)
    );


    uart #(
        .CLOCK(`F_CLK),
        .BAUDRATE(`BAUDRATE)
    ) uart_u(
        .clk(clk_100M),
        .rst(rst),

        .rx(rx),
        .tx(tx),

        .tx_data(si_ft245_tx_data),
        .tx_rdy(si_ft245_tx_rdy),
        .tx_ack(si_ft245_tx_ack),

        .rx_data(si_ft245_rx_data),
        .rx_rdy(si_ft245_rx_rdy),
        .rx_ack(si_ft245_rx_ack),

        .tx_enable(1'b1),
        .rx_enable(1'b1)
    );


    `ifdef COCOTB_SIM   // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,tx_rx);
            #1;
        end
    `endif

endmodule // adc_block
