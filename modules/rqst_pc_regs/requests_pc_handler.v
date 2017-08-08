

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
    parameter DATA_WIDTH = 16,
) (
                                // Description                  Type            Width
    // Basic
    input clk,                  // fpga clock                   input           1
    input rst,                  // synch reset                  input           1

    // Interface with Request PC Register
    input [DATA_WIDTH-1:0] request_reg_data,
                            // request_reg data
    output request_reg_ack,

    // Output signals
    output reg start_o = 1'b0,
    output reg stop_o = 1'b0,
    output reg rqst_ch1 = 1'b0,
    output reg rqst_ch2 = 1'b0,
    output reg rqst_trigger_status = 1'b0,
    output reg reset_o = 1'b0,

);

    wire    rqst_reset,
            rqst_start,
            rqst_stop,
            rqst_conf;

    assign rqst_conf = request_reg_data[3];
    assign rqst_stop = request_reg_data[2];
    assign rqst_reset = request_reg_data[1];
    assign rqst_start = request_reg_data[0];

    // Asynchronous acknowledge.
    /* If the ack is a sequential register, data will be duplicated since
    it stays unerased during 2 clocks. */
    assign request_reg_ack = |request_reg_data;

    // Control of the requests received via Request_Register
    always @(posedge clk) begin
        request_reg_ack <= 1'b0;
        start_o <= 1'b0;
        reset_o <= 1'b0;
        rqst_conf_o <= 1'b0;
        stop_o <= stop_o;
        if (rqst_start == 1'b1) begin
            stop_o <= 1'b0;
            start_o <= 1'b1;
        end
        if (rqst_reset == 1'b1) begin
            reset_o <= 1'b1;
        end
        if (rqst_stop == 1'b1) begin
            stop_o <= 1'b1; //stays in 1 until a 'start' rqst.
        end
        if(rqst_conf == 1'b1) begin
            rqst_conf_o <= 1'b1;
        end
    end

end module
