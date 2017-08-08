

/*
    Requests from PC Handler Module

    This module has the logic to handle the Request PC Register and send the corresponding signals to other modules.

    PROBLEM: | of 16 bits
    SOLUTION: delete ACK. Request register keeps it's value during one
    clock and if you miss it, you miss it.
    That's not a problem because reading that register is this module's main job!

*/

`timescale 1ns/1ps

module requests_pc_handler  #(
    parameter REG_ADDR_WIDTH = `__REG_ADDR_WIDTH,
    parameter REG_DATA_WIDTH = `__REG_DATA_WIDTH,
    parameter MY_ADDR = 0,
    parameter MY_RESET_VALUE = 0
) (
                                // Description                  Type            Width
    // Basic
    input clk,                  // fpga clock                   input           1
    input rst,                  // synch reset                  input           1

    // Address and data simple interface
    input [ADDR_WIDTH-1:0] si_addr,
    input [DATA_WIDTH-1:0] si_data,
    input si_rdy,

    // Output signals
    output start_o,
    output stop_o,
    output rqst_ch1,
    output rqst_ch2,
    output rqst_trigger_status,
    output reset_o

);

    reg  [REG_DATA_WIDTH-1:0]  rqst_array = 0;

    assign start_o = rqst_array[`__START_IDX];
    // this is important!!
    // When a request for data arrives, a STOP must be send to stop writing RAM, avoiding
    //  data corruption.
    // Also, if you ask for CH1 and later CH2, you probably want them both in the same
    //  time interval.
    // This won't be necessary if the channel data request is made with both STOP and RQST_CHx bits set.
    assign stop_o = rqst_array[`__STOP_IDX] | rqst_array[`__RQST_CH1_IDX] | rqst_array[`__RQST_CH2_IDX];
    assign rqst_ch1 = rqst_array[`__RQST_CH1_IDX];
    assign rqst_ch2 = rqst_array[`__RQST_CH2_IDX];
    assign rqst_trigger_status = rqst_array[`__RQST_TRIG_IDX];

    reg [3:0] i = 0;
    // Control of the requests received via Request_Register
    always @(posedge clk) begin
        for( i=0 ; i<16 ; i=i+1) rqst_array[i] <= 1'b0;
        if(rst == 1'b1) begin

        end else begin
            if(si_rdy == 1'b1 && si_addr = MY_ADDR) begin
                for( i=0 ; i<16 ; i=i+1) rqst_array[i] <= si_data[i];
            end
    end

end module

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
