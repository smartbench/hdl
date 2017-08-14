
`timescale 1ns/1ps

module ft245_interface #(
    parameter CLOCK_PERIOD_NS = 10
)(
    input clk,
    input rst,

    // ft245 rx interface
    input [7:0] rx_data_245,
    input rxf_245,
    output reg rx_245=1'b1,

    // ft245 tx interface
    output reg [7:0] tx_data_245= 8'b0,
    input txe_245,
    output reg wr_245= 1'b1,
    output reg tx_oe_245=1'b0,

    // simple interface
    output reg [7:0] rx_data_si = 8'd0,
    output reg rx_rdy_si = 1'b0,
    input rx_ack_si,

    input [7:0] tx_data_si,
    input tx_rdy_si,
    output reg tx_ack_si=1'b0
);


    localparam WAIT_TIME_RX = 30.0;
    localparam INACTIVE_TIME_RX = 14.0;
    localparam SETUP_TIME_TX = 5.0;
    localparam HOLD_TIME_TX = 5.0;
    localparam ACTIVE_TIME_TX = 30.0;

    localparam CNT_WAIT_RX = $rtoi($ceil(WAIT_TIME_RX/CLOCK_PERIOD_NS));
    localparam CNT_INACTIVE_RX = $rtoi($ceil(INACTIVE_TIME_RX/CLOCK_PERIOD_NS));
    localparam CNT_SETUP_TX = $rtoi($ceil(SETUP_TIME_TX/CLOCK_PERIOD_NS));
    localparam CNT_ACTIVE_TX = $rtoi($ceil(ACTIVE_TIME_TX/CLOCK_PERIOD_NS));
    localparam MAX_CNT = CNT_WAIT_RX;

/*  // Forcing itor
    localparam CNT_WAIT_RX = $rtoi( $ceil( $itor(WAIT_TIME_RX) / CLOCK_PERIOD_NS ) );
    localparam CNT_INACTIVE_RX = $rtoi( $ceil( $itor(INACTIVE_TIME_RX)/ CLOCK_PERIOD_NS ) );
    localparam CNT_SETUP_TX = $rtoi( $ceil( $itor(SETUP_TIME_TX) / CLOCK_PERIOD_NS ) );
    localparam CNT_ACTIVE_TX = $rtoi( $ceil( $itor(ACTIVE_TIME_TX) / CLOCK_PERIOD_NS ) );
    localparam MAX_CNT = CNT_WAIT_RX;
*/
/*  // HARDCODED
    localparam CNT_WAIT_RX = 3; // 30/10
    localparam CNT_INACTIVE_RX = 2; // 14/10
    localparam CNT_SETUP_TX = 1; // 5/10
    localparam CNT_ACTIVE_TX = 3; // 30/10
    localparam MAX_CNT = CNT_WAIT_RX;
*/

    initial begin
        //$display("CLOCK_PERIOD_NS:: CLOCK_PERIOD_NS=%s", CLOCK_PERIOD_NS);
        $display("CNT_WAIT_RX:: CNT_WAIT_RX=%d", CNT_WAIT_RX);
        $display("CNT_INACTIVE_RX:: CNT_INACTIVE_RX=%d", CNT_INACTIVE_RX);
        $display("CNT_SETUP_TX:: CNT_SETUP_TX=%d", CNT_SETUP_TX);
        $display("CNT_ACTIVE_TX:: CNT_ACTIVE_TX=%d", CNT_ACTIVE_TX);
        $display("MAX_CNT:: MAX_CNT=%d", MAX_CNT);
    end

    localparam ST_IDLE = 0;
    localparam ST_WAIT_RX = 1;
    localparam ST_INACTIVE_RX =2;
    localparam ST_SETUP_TX = 3;
    localparam ST_WAIT_TX = 4;

    reg [2:0] state = ST_IDLE;
    reg [$clog2(MAX_CNT):0] cnt=0;

    always @* tx_ack_si <=  (state==ST_IDLE) ?
        (rxf_245 & rx_rdy_si & ~txe_245 & tx_rdy_si) : 1'b0;

    always @(posedge clk) begin
        if (rst == 1'b1) begin
            state <= ST_IDLE;
            rx_245 <= 1'b1;
            tx_oe_245 <= 1'b0;
            cnt <= 3'd0;
            wr_245 <= 1'b1;
            rx_rdy_si <= 1'b0;
        end else begin
            rx_rdy_si <= rx_rdy_si & ~rx_ack_si;
            wr_245 <= 1'b1;
            case (state)
                ST_IDLE:
                begin
                    if (rxf_245 == 1'b0  && rx_rdy_si == 1'b0) begin
                        rx_245 <= 1'b0;
                        cnt <= 0;
                        state <= ST_WAIT_RX;
                    end else if(txe_245 == 1'b0 && tx_rdy_si == 1'b1) begin
                        tx_data_245 <= tx_data_si;
                        tx_oe_245 <= 1'b1;
                        state <= ST_SETUP_TX;
                    end
                end

                ST_WAIT_RX:
                begin
                    cnt <= cnt + 1;
                    if (cnt == CNT_WAIT_RX-1) begin
                        rx_245 <= 1'b1;
                        state <= ST_INACTIVE_RX;
                        cnt <= 0;
                        rx_data_si <= rx_data_245;
                        rx_rdy_si <= 1'b1;
                    end
                end

                ST_INACTIVE_RX:
                begin
                    cnt <= cnt + 1;
                    if (cnt == CNT_INACTIVE_RX-1) begin
                        state <= ST_IDLE;
                    end
                end

                ST_SETUP_TX:
                begin
                    state <= ST_WAIT_TX;
                    wr_245 <= 1'b0;
                    cnt <= 0;
                end

                ST_WAIT_TX: // Espera ACTIVE_TIME_TX
                begin
                    cnt <= cnt + 1;
                    wr_245 <= 1'b0;
                    if (cnt == CNT_ACTIVE_TX-1) begin
                        cnt <= 0;
                        tx_oe_245 <= 1'b0;
                        state <= ST_IDLE;
                        wr_245 <= 1'b1;
                    end
                end

                default:  rx_245 <= 1'b1;
            endcase
        end
    end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("waveform.vcd");
  $dumpvars (0,ft245_interface);
  #1;
end
`endif

endmodule
