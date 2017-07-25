
/*
    A simple fully associative request register.

    The module checks if the addr bus is equal to the register addr.
    Value is updated when the condition is true.
    When data is acknowledged, the register is erased.

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name                Modified by         Comment
                2017/07/23      0.1             request_reg         IP                  Module created.

    ToDo:
                Date            Suggested by    Priority    Activity                Description

    Releases:   In development ...
*/

`timescale 1ns/1ps

module fa_request_register #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 16,
    parameter MY_ADDR = 4'ha,
    parameter MY_RESET_VALUE = 4'h0
) (
    // Basic signals
    input clk,
    input rst,

    // Address and data simple interface
    input [ADDR_WIDTH-1:0] si_addr,
    input [DATA_WIDTH-1:0] si_data,
    input si_rdy,
    output si_ack,

    // Register value
    input data_ack,
    output reg [DATA_WIDTH-1:0] data
);

    // Asynchronous acknowledge.
    assign si_ack = si_rdy & (si_addr==MY_ADDR);

    always @( posedge(clk) ) begin
        if ( rst == 1'b1 || data_ack == 1'b1) begin
            data <= MY_RESET_VALUE;
        end else begin
            if ( si_rdy == 1'b1 && si_addr == MY_ADDR ) begin
                data <= si_data;
            end
        end
    end
endmodule
