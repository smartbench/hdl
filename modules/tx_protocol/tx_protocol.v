/*
    Tx protocol module.
    This module sends sampled data, or trigger status.


    The state machine have two possible states.
    It's on ST_IDLE state when there is no data to send.
    When one of the input interfaces are ready, the state changes to ST_SENDING
    and {_data, _rdy and _ack} of the selected source are connected to the Output SI,
    so this module will remain transparent until EOF is detected.
    When EOF is detected, status changes back to IDLE.

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci
    Version:
                Date            Modified by         Comment
                2017/07/31      IP                  Module created. Only IO signals writen. Behavioural test hasn't been done.
                2017/08/05      AK                  Completing module, adding testbench.
    ToDo:
                Date            Suggested by        Comment
                2017/08/02      IP                  Package all input interfaces in a flattened 2D array ??
*/

`timescale 1ns/1ps

module tx_protocol #(
    parameter DATA_WIDTH = 8,
    parameter TX_WIDTH = 8,
    parameter SOURCES = 3
) (
    // Basic synchronous signals
    input clk,
    input rst,

    // SI - Output (FT245)
    output reg [TX_WIDTH-1:0] tx_data,
    output reg tx_rdy,
    input tx_ack,

    // SI - Channel 1
    input [DATA_WIDTH-1:0] ch1_data,    // Data bus
    input ch1_rdy,                      // Valid data in the bus
    output ch1_ack,                     // Ack
    input ch1_eof,                      // No more channel 1 data avalaible

    // SI - Channel 2
    input [DATA_WIDTH-1:0] ch2_data,    // Data bus
    input ch2_rdy,                      // Valid data in the bus
    output ch2_ack,                     // Ack
    input ch2_eof,                      // No more channel 1 data avalaible

    // SI - Trigger status
    input [DATA_WIDTH-1:0] tr_data,     // Data bus
    input tr_rdy,                       // Valid data in the bus
    output tr_ack,                      // Ack
    input tr_eof                        // No more channel 1 data avalaible
);

    reg [$clog2(SOURCES)-1:0] i = 0;

    localparam  ST_IDLE = 0,
                ST_SENDING = 1;

    reg state = 0;

    reg [1:0] source_interface;

    // 2D array packing input interfaces.
    wire [DATA_WIDTH-1:0] input_data [0:2];
    wire [0:2] input_rdy;
    wire [0:2] input_ack;
    wire [0:2] input_eof;

    assign input_data[0] = tr_data;
    assign input_data[1] = ch1_data;
    assign input_data[2] = ch2_data;

    assign input_rdy[0] = tr_rdy;
    assign input_rdy[1] = ch1_rdy;
    assign input_rdy[2] = ch2_rdy;

    assign tr_ack = input_ack[0];
    assign ch1_ack = input_ack[1];
    assign ch2_ack = input_ack[2];

    assign input_eof[0] = tr_eof;
    assign input_eof[1] = ch1_eof;
    assign input_eof[2] = ch2_eof;

    // Default value & MUXES
    always @* begin
        tx_data = 0;
        tx_rdy = 0;
        for (i = 0; i < SOURCES; i = i +1) input_ack[i] = 1'b0;
        if(state == ST_SENDING) begin
            tx_data = input_data[source_interface];
            tx_rdy = input_rdy[source_interface];
            input_ack[source_interface] = tx_ack;
        end
    end

    // State machine
    always @( posedge(clk) ) begin
        if ( rst ) begin
            state <= ST_IDLE;
            source_interface <= 0;
        end else begin
            if( ( state == ST_IDLE ) && ( |input_rdy == 1'b1 ) ) begin
                state <= ST_SENDING;
                for (i = 0; i<SOURCES ; i=i+1) if(input_rdy[i] == 1'b1) source_interface <= i;
            end
            if( ( state == ST_SENDING ) ) begin
                if( input_eof[source_interface] == 1'b1 ) begin
                    state <= ST_IDLE;
                end
            end
        end
    end

    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("waveform.vcd");
      $dumpvars (0,tx_protocol);
      #1;
    end
    `endif

endmodule
