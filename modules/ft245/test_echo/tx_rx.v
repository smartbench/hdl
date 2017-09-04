

`timescale 1ns/1ps

`define ECHO_1
//`define ECHO_2

`define WIDTH 8
`define F_CLK 99000000
`define CLOCK_PERIOD_NS 10

module tx_rx (
    input clk_i,
    input rst_i,

    // FT245 interface
    inout [`WIDTH-1:0] in_out_245,
    input rxf_245,
    output rx_245,
    input txe_245,
    output wr_245,

    output clk_o,
    output reg [7:0] leds
);

    // PLL output clock
    wire clk_100M;
    wire pll_lock;

    wire [7:0] in_245;
    wire [7:0] out_245;
    wire tx_oe_245;

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

    // initial reset
    assign rst = ~start | rst_i;

    always @(posedge clk_100M) begin
        rst_cnt <= rst_cnt + 1;
        if(rst_cnt == 1000) start <= 1;
    end

    always @(posedge clk_100M) begin
        if(rst)
            if(pll_lock) leds <= 8'h81;
            else leds <= 8'hFF;
        //if(rx==1'b0) leds <= 8'h55;
        /*ledCounter <= ledCounter + 1;
        if(ledCounter == aa) begin
            ledCounter <= 0;
            leds <= leds + 1;
        end*/
        if(si_ft245_rx_rdy) leds <= si_ft245_rx_data;
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
    ) pll_100M_u (
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk_i),
        .PLLOUTCORE(clk_100M),
        .LOCK(pll_lock)
    );

    ft245_interface #(
        .CLOCK_PERIOD_NS(`CLOCK_PERIOD_NS)
    ) ft245_u (
        .clk(clk_100M),
        .rst(rst),

        .rx_data_245(in_245),
        .rxf_245(rxf_245),
        .rx_245(rx_245),

        .tx_data_245(out_245),
        .txe_245(txe_245),
        .wr_245(wr_245),
        .tx_oe_245(tx_oe_245),

        .rx_data_si(si_ft245_rx_data),
        .rx_rdy_si(si_ft245_rx_rdy),
        .rx_ack_si(si_ft245_rx_ack),

        .tx_data_si(si_ft245_tx_data),
        .tx_rdy_si(si_ft245_tx_rdy),
        .tx_ack_si(si_ft245_tx_ack)
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

// echo
`ifdef ECHO_1

    assign si_ft245_tx_data = si_ft245_rx_data;
    assign si_ft245_tx_rdy = si_ft245_rx_rdy;
    assign si_ft245_rx_ack = si_ft245_tx_ack;

`else

    assign si_ft245_tx_data = dl_data[N-1];
    assign si_ft245_tx_rdy = dl_rdy[N-1];
    assign si_ft245_rx_ack = si_ft245_rx_rdy & ~dl_rdy[0] ;

    localparam N=5;
    reg [7:0] dl_data[0:N-1];
    reg [N-1:0] dl_rdy;

    integer i,j;
    initial begin
        for(i=0;i<N;i=i+1) begin
            dl_rdy[i] <= 1'b0;
            dl_data[i] <= 8'b0;
        end
    end

    always @(posedge clk_100M) begin
        if(si_ft245_tx_ack) begin
            // all to the left
            for (i=1;i<N;i=i+1) begin
                dl_data[i] <= dl_data[i-1];
                dl_rdy[i] <= dl_rdy[i-1];
            end
            dl_data[0] <= 0;
            dl_rdy[0] <= 1'b0;
        end else begin
            for (i=1;i<N;i=i+1) begin
                if(dl_rdy[i] == 1'b0) begin //free space
                    for (j=1;j<=i;j=j+1) begin
                        dl_data[j] <= dl_data[j-1];
                        dl_rdy[j] <= dl_rdy[j-1];
                    end
                    dl_data[0] <= 0;
                    dl_rdy[0] <= 1'b0;
                end
            end
        end
        if(dl_rdy[0] == 1'b0) begin
            dl_data[0] <= si_ft245_rx_data;
            dl_rdy[0] <= si_ft245_rx_rdy;
        end
    end

`endif


`ifdef COCOTB_SIM   // COCOTB macro
    initial begin
        $dumpfile ("waveform.vcd");
        $dumpvars (0,tx_rx);
        #1;
    end
`endif

endmodule
