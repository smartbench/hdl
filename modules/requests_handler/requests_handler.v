

/*
    Requests from PC Handler Module

    This module has the logic to handle the requests from the pc.
    The input works like a register, with addr,data and rdy.
    Whenever written, it sends the corresponding signals, but read value is
    not stored
*/

`timescale 1ns/1ps

`include "conf_regs_defines.v"

module requests_handler  #(
    parameter REG_ADDR_WIDTH = `__REG_ADDR_WIDTH,
    parameter REG_DATA_WIDTH = `__REG_DATA_WIDTH,
    parameter MY_ADDR = 0,
    parameter MY_RESET_VALUE = 0
) (
    // Basic
    input clk,                  // fpga clock
    input rst,                  // synch reset

    // Address and data simple interface
    input [REG_ADDR_WIDTH-1:0] si_addr,
    input [REG_DATA_WIDTH-1:0] si_data,
    input si_rdy,

    // Output signals
    output start_o,
    output stop_o,
    output rqst_ch1,
    output rqst_ch2,
    output rqst_trigger_status_o,
    output reset_o

);

    reg  [REG_DATA_WIDTH-1:0]  rqst_array = 0;

    assign start_o = rqst_array[`__RQST_START_IDX];
    // this is important!!
    // When a request for data arrives, a STOP must be send to stop writing RAM, avoiding
    //  data corruption.
    // Also, if you ask for CHA and later CHB, you probably want them both in the same
    //  time interval.
    // This won't be necessary if the channel data request is made with both STOP and RQST_CHx bits set.
    assign stop_o = rqst_array[`__RQST_STOP_IDX] | rqst_array[`__RQST_CHA_IDX] | rqst_array[`__RQST_CHB_IDX];
    assign rqst_ch1 = rqst_array[`__RQST_CHA_IDX];
    assign rqst_ch2 = rqst_array[`__RQST_CHB_IDX];
    assign rqst_trigger_status_o = rqst_array[`__RQST_TRIG_IDX];
    assign reset_o = rqst_array[`__RQST_RST_IDX];

    integer i = 0;
    // Control of the requests received via Request_Register
    always @(posedge clk) begin
        for( i=0 ; i<REG_DATA_WIDTH ; i=i+1)
            rqst_array[i] <= 1'b0;
        if(rst == 1'b1) begin
            // ...
        end else begin
            if(si_rdy == 1'b1 && si_addr == MY_ADDR) begin
                for( i=0 ; i<16 ; i=i+1)
                    rqst_array[i] <= si_data[i];
            end
        end
    end

/*
always @(posedge clk) begin
    start_o <= 1'b0;
    reset_o <= 1'b0;
    rqst_ch1_o <= 1'b0;
    rqst_ch2_o <= 1'b0;
    rqst_trigger_status_o <= 1'b0;
    if(rst == 1'b1) begin
        stop <= 1'b0;
    end else begin
        if(si_rdy == 1'b1 && si_addr = MY_ADDR) begin
            start_o <= start_i;
            reset_o <= reset_i;
            rqst_ch1_o <= rqst_ch1_i;
            rqst_ch2_o <= rqst_ch2_i;
            rqst_trigger_status_o <= rqst_trigger_status_i;

            if (start_i == 1'b1) stop_o <= 1'b0;
            if (stop_i == 1'b1) stop_o <= 1'b1;
        end
    end
end
*/

endmodule
