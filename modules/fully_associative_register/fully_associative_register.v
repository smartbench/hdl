
/*
    A simple fully associative register.

    The module checks if the addr bus is equal to the register addr.
    If it's, the register is updated.

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name                Modified by         Comment
                2017/07/23      0.1             first_approach      AK                  Starting development...
                2017/07/24      0.2             full_associative    IP                  Changed mux selection of writing, to full associative registers.

    ToDo:
                Date            Suggested by    Priority    Activity                Description

    Releases:   In development ...
*/

`include "../../../inc/conf_regs_defines.v"
`timescale 1ns/1ps

module fully_associative_register #(
    parameter REG_ADDR_WIDTH = `__REG_ADDR_WIDTH,
    parameter REG_DATA_WIDTH = `__REG_DATA_WIDTH,
    parameter MY_ADDR = 4'ha,
    parameter MY_RESET_VALUE = 4'h0
) (
    // Basic signals
    input clk,
    input rst,

    // Address and data simple interface
    input [REG_ADDR_WIDTH-1:0] si_addr,
    input [REG_DATA_WIDTH-1:0] si_data,
    input si_rdy,
    output si_ack,

    // Register value
    output reg [REG_DATA_WIDTH-1:0] data = MY_RESET_VALUE
);

    // Asynchronous acknowledge.
    assign si_ack = si_rdy & (si_addr==MY_ADDR);

    always @( posedge(clk) ) begin
        if ( rst == 1'b1 ) begin
            data <= MY_RESET_VALUE;
        end else begin
            if ( si_rdy == 1'b1 && si_addr == MY_ADDR ) begin
                data <= si_data;
            end
        end
    end

endmodule