

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
                Date            Number          Name                Modified by         Comment
                2017/07/23      0.1             first_approach      AK                  Starting development...
                2017/07/24      0.2             full_associative    IP                  Changed mux selection of writing, to full associative registers.

    ToDo:
                Date            Suggested by    Priority    Activity                Description

    Releases:   In development ...
*/

`define __FULLY_ASSOCIATIVE_REGISTER_INCLUDED

`ifndef COCOTB_SIM
    `include "conf_regs_defines.v"
    `include "fully_associative_register.v"
`else
    `include "../conf_regs_defines.v"
    `include "../fully_associative_register.v"
`endif

`timescale 1ns/1ps

module conf_regs  #(
    parameter ADDR_WIDTH = `__ADDR_WIDTH,
    parameter DATA_WIDTH = `__DATA_WIDTH,
    parameter NUM_REGS = `__NUM_REGS,
    parameter REGISTERS_RESET_VALUES = `__IV_ARRAY
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
    output register_ack,            // Acknowledge              output          1

    output [DATA_WIDTH * NUM_REGS-1:0] registers
                                    // registers                output          DATA_WIDTH * NUM_REGS (2D array)

);

    // ack output of all registers
    wire  [NUM_REGS-1:0]array_ack;

    // Oring the whole ack vector
    assign register_ack = |array_ack;

    // Using 2D vector is nicer
    wire [DATA_WIDTH-1:0] array_registers [0:NUM_REGS-1];

    // Assign a 2D matrix to vector output
    genvar h;
    generate
        for(h = 0 ; h < NUM_REGS ; h = h + 1)
            assign registers [ (h + 1) * DATA_WIDTH - 1  : h * DATA_WIDTH ] = array_registers [h] [DATA_WIDTH-1:0] ;
    endgenerate

    // Instantiation of registers
    generate
        for(h = 0 ; h < NUM_REGS ; h = h + 1) begin: __REGISTER_INSTANTIATION
            fully_associative_register #(
                .ADDR_WIDTH     ( ADDR_WIDTH )                      ,
                .DATA_WIDTH     ( DATA_WIDTH )                      ,
                .MY_ADDR        ( h+`__REGS_STARTING_ADDR )         ,
                .MY_RESET_VALUE ( REGISTERS_RESET_VALUES[h] )
                ) register (
                    .clk        (clk)                   ,
                    .rst        (rst)                   ,
                    .si_addr    (register_addr)         ,
                    .si_data    (register_data)         ,
                    .si_rdy     (register_rdy)          ,
                    .si_ack     (array_ack[h])          ,
                    .data       (array_registers[h])
            );
        end
    endgenerate

    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,conf_regs);
            #1;
        end
    `endif

endmodule
