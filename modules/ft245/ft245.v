
`timescale 1ns/1ps
module ft245_interface
( 

    // ft245 rx interface
    input [7:0] rx_data_245,
    input rxf_245,
    output reg rx_245=1'b1,

    // ft245 tx interface
    output reg [7:0] tx_data_245= 8'b0,
    input txe_245,
    output reg tx_245= 1'b1,
    output reg tx_oe_245=1'b0,

    // 
    input clk,
    input rst,

    // simple interface
    output reg [7:0] rx_data_si = 8'd0,
    output reg rx_rdy_si = 1'b0,
    input rx_ack_si,

    input [7:0] tx_data_si,
    input tx_rdy_si,
    output reg tx_ack_si=0
);

    parameter CLOCK_PERIOD_NS = 10;

    localparam WAIT_TIME_RX = 30;
    localparam INACTIVE_TIME_RX = 14;
    localparam SETUP_TIME_TX = 5;
    localparam HOLD_TIME_TX = 5;
    localparam ACTIVE_TIME_TX = 30;


    localparam CNT_WAIT_RX = $rtoi($ceil(WAIT_TIME_RX/CLOCK_PERIOD_NS));
    localparam CNT_INACTIVE_RX = $rtoi($ceil(INACTIVE_TIME_RX/CLOCK_PERIOD_NS));

    localparam CNT_SETUP_TX = $rtoi($ceil(SETUP_TIME_TX/CLOCK_PERIOD_NS));
    localparam CNT_ACTIVE_TX = $rtoi($ceil(ACTIVE_TIME_TX/CLOCK_PERIOD_NS));
    localparam MAX_CNT = CNT_WAIT_RX;


    localparam ST_IDLE = 0;
    localparam ST_WAIT_RX = 1;
    localparam ST_INACTIVE_RX =2;
    localparam ST_SETUP_TX = 3;
    localparam ST_WAIT_TX = 4;

    reg [2:0] state =0;
    reg [$clog2(MAX_CNT)-1:0] cnt=0;

    always @* tx_ack_si <= (state==ST_IDLE)? tx_rdy_si & ~txe_245 & rxf_245 : 1'b0;
    
    always @(posedge clk) begin
        if (rst == 1'b1) begin
            state <= ST_IDLE;
            rx_245 <= 1'b1;
            cnt <= 3'd0;
        end else begin
            rx_rdy_si <= (rx_rdy_si == 1'b0)? 1'b0 : rx_rdy_si ^ rx_ack_si;
            tx_245 <= 1'b1;
            case (state)
                ST_IDLE: 
                begin
                    if (rxf_245 == 1'b0  && rx_rdy_si == 1'b0) begin
                        rx_245 <= 1'b0;
                        cnt <= 0;
                        state <= ST_WAIT_RX;
                    end else if ( tx_rdy_si == 1'b1  && txe_245 == 1'b0 ) begin
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
                    tx_245 <= 1'b0;
                    cnt <= 0;
                end
                
                ST_WAIT_TX: // Espera ACTIVE_TIME_TX
                begin
                    cnt <= cnt + 1;
                    tx_245 <= 1'b0;
                    if (cnt == CNT_ACTIVE_TX-1) begin
                        tx_oe_245 <= 1'b0;
                        state <= ST_IDLE;
                        tx_245 <= 1'b1;
                    end
                end
                
                default:  rx_245 <= 1'b0;
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
