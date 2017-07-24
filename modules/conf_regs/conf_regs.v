

/*
    Configuration Registers Module

    This module contains the configuration registers.
    These registers are loaded with the Simple Interface

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name            Modified by     Comment
                2017/07/23      0.1             first_approach  AK               Starting development...

    ToDo:
                Date            Suggested by    Priority    Activity                Description

    Releases:   In development ...
*/

`timescale 1ns/1ps

module conf_regs  #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 16,
    parameter NUM_REGS = 20
) (
                                // Description                  Type            Width
    // Basic
    input clk,                      // fpga clock               input           1
    input rst,                      // synch reset              input           1

    // SI Interface
    input [ADDR_WIDTH-1:0] register_addr,
                                    // address                  input           ADDR_WIDTH (def. 8)
    input [DATA_WIDTH-1:0] register_data,
                                    // data                     input           DATA_WIDTH (def. 8)
    input register_rdy,             // data ready               input           1
    output reg register_ack = 1'b0, // Acknowledge              output          1
    output reg register_err = 1'b0, // Error (ex: wrong addr)   output          1
    output [DATA_WIDTH * NUM_REGS-1:0] registers,
                                    // registers                    output          DATA_WIDTH * NUM_REGS (2D array)
    output reg request_rdy,         // request ready for reading    output          1
    input request_ack,              // request read                 input           1

);


    // Assign a 2D matrix to register
    reg [DATA_WIDTH-1:0] array_registers [0:NUM_REGS-1];
    genvar h;
    generate
        for(h = 0 ; h < NUM_REGS ; h = h + 1)
            assign registers [ (h + 1) * DATA_WIDTH - 1  : h * DATA_WIDTH ] = array_registers [h] [DATA_WIDTH-1:0] ;
    endgenerate

    // loop iterator
    integer k;

    // integer conversion for address
    integer addr_i;
    assign addr_i = register_addr;

    always @(posedge clk) begin
        register_ack <= 1'b0;
        if (reset == 1'b1) begin                                            // RESET
            request_rdy <= 1'b0;
            for( k=0 ; k<NUM_REGS ; k=k+1) array_registers[k] <= 0;
        end else begin
            if (request_ack <= 1'b1) array_registers[0] <= 0;
            if (register_rdy == 1'b1) begin
                if (addr_i == 0) begin
                    // REQUEST FROM PC:
                    // start, stop, reset, search for new modules, etc...
                    if (request_ack <= 1'b1) array_registers[0] <= register_data;
                    else array_registers[0] <= array_registers[0] | register_data;
                    register_ack <= 1'b1;
                    request_rdy <= 1'b1;
                end else if (addr_i < NUM_REGS) begin
                    array_registers[addr_i] <= register_data;
                    register_ack <= 1'b1;
                end
            end
        end
    end


    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,conf_regs);
            #1;
        end
    `endif

endmodule
