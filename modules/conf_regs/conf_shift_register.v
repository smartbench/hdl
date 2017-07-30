/*
    Configuration Register Module

    A module to send the data alocated in registers.
    When it receives a request to send the data (bit rqst_regs), it saves the current status of
    the array of registers' bits in a shift register.
    Then, with each ACK, shifts TX_WIDTH bits to the right.
    The output tx_data is wired to the TX_WIDTH lowest bits of the shift register.
    The empty bit is set to 1 when the shift register is empty, to notify that there is
    no more data to read from it.

    NOTE: it has to access the entire matrix containing all the registers data.

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name                Modified by         Comment
                2017/07/26      0.1             conf_shift_reg      AK                  First version
                2017/07/26      0.2             conf_shift_reg      AK                  The shifting is controlled with ACK

    ToDo:
                Date            Suggested by    Priority    Activity                Description
                2017/07/26      AK              HIGH        TEST                    TEST!!

    Releases:   In development ...
*/

`include "conf_regs_defines.v"
`timescale 1ns/1ps

module conf_shift_register #(
    parameter NUM_REGS = `__NUM_REGS,
    parameter DATA_WIDTH = `__DATA_WIDTH,
    parameter TX_WIDTH = `__TX_WIDTH
) (
    // Basic signals
    input clk,
    input rst,

    // Array of bits from Registers
    input [DATA_WIDTH * NUM_REGS-1:0] registers,
                          // registers      output      DATA_WIDTH * NUM_REGS (2D array)

    // Address and data simple interface
    input request,                  // This bit loads the current array in the shift register
    input ack,                      // This bit forces a shift: >> TX_WIDTH
    output [TX_WIDTH-1:0] tx_data,   // This is wired to the TX_WIDTH lowest bits of the shift register
    output reg empty                // This notifies when all the data was already shifted.

);

    localparam  SHIFT_COUNT = DATA_WIDTH/TX_WIDTH * NUM_REGS  - 1 ;

    localparam  ST_INACTIVE = 0,
                ST_SENDING = 1;

    reg [DATA_WIDTH * NUM_REGS-1:0] shift_register;
    reg [1:0] state = ST_INACTIVE;
    reg [15:0] counter = SHIFT_COUNT;

    assign tx_data = shift_register[TX_WIDTH-1:0];

    always @( posedge(clk) ) begin
        if ( rst == 1'b1 ) begin
            empty <= 1'b0;
            counter <= SHIFT_COUNT;
        end else begin
            if( state == ST_INACTIVE && request == 1'b1) begin
                // Load registers data in shift register
                shift_register <= registers;
                empty <= 1'b0;
                counter <= SHIFT_COUNT;
                state <= ST_SENDING;
            end

            if( state == ST_SENDING && ack == 1'b1 ) begin   // only shifts when last
                                    // data was ACKed
                shift_register <= (shift_register >> TX_WIDTH);
                if(counter != 0) begin
                    // send next packet
                    counter <= counter - 1;
                end else begin
                    // End
                    empty <= 1'b1;
                    counter <= SHIFT_COUNT;
                    state <= ST_INACTIVE;
                end
            end
        end
    end

    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,conf_shift_register);
            #1;
        end
    `endif

endmodule
