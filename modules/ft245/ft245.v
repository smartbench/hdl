
`timescale 1ns/1ps
module ft245_input
( 

    // ft245 rx interface
    input [7:0] rx_data_245,
    input rxf_245,
    output reg rx_245=1'b1,

    // ft245 tx interface
    input [7:0] tx_data_245,
    input txe_245,
    output reg tx_245= 1'b1,
    output reg tx_oe_245=1'b0,

    // 
    input clk,
    input rst,

    // simple interface
    output reg [7:0] rx_data_si = 8'd0,
    output reg rx_rdy_si = 1'b0,
    input rx_ack_si
);

    parameter CLOCK_PERIOD_NS = 10;

    localparam WAIT_TIME_RX = 30;
    localparam INACTIVE_TIME_RX = 14;

    localparam CNT_WAIT_RX = $rtoi($ceil(WAIT_TIME_RX/CLOCK_PERIOD_NS));
    localparam CNT_INACTIVE_RX = $rtoi($ceil(INACTIVE_TIME_RX/CLOCK_PERIOD_NS));
    localparam MAX_CNT = CNT_WAIT_RX;


    localparam ST_IDLE = 0;
    localparam ST_WAIT_RX = 1;
    localparam ST_INACTIVE_RX =2;

    reg [1:0] state =0;
    reg [$clog2(MAX_CNT)-1:0] cnt=0;

    
    always @(posedge clk) begin
        if (rst == 1'b1) begin
            state <= ST_IDLE;
            rx_245 <= 1'b1;
            cnt <= 3'd0;
        end else begin
            rx_rdy_si <= rx_rdy_si ^ rx_ack_si;
            case (state)
                ST_IDLE:
                    if (rxf_245 == 1'b0  && rx_rdy_si == 1'b0) begin
                        rx_245 <= 1'b0;
                        cnt <= 3'd0;
                        state <= ST_WAIT_RX;
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
                default:
                    rx_245 <= 1'b0;
            endcase
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
