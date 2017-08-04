/*
    Tx protocol module.
    This module sends sampled data, or trigger status.

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci
    Version:
                Date           Modified by         Comment
                2017/07/31     IP                  Module created. Only IO signals writen. Behavioural test hasn't been done.
    ToDo:
                Date           Suggested by        Comment
                2017/08/02     IP                  Package all input interfaces in a flattened 2D array ??
*/

/* WAITING FOR DEFINES:
    TRIGGER STATUS requested
    SAMPLED DATA requested */

module tx_protocol #(
    parameter DATA_WIDTH = 8,
    parameter TX_WIDTH = 8
) (
    // Basic synchronous signals
    input clk,
    input rst,

    // Output interface
    output reg [TX_WIDTH-1:0] tx_data,
    output reg tx_rdy,
    output reg tx_ack,

    // SI interface for channel 1
    input [DATA_WIDTH-1:0] ch1_data,    // Data bus
    input ch1_rdy,                      // Valid data in the bus
    output ch1_ack,                     // Ack
    input ch1_eof,                      // No more channel 1 data avalaible

    // SI interface for channel 2
    input [DATA_WIDTH-1:0] ch2_data,    // Data bus
    input ch2_rdy,                      // Valid data in the bus
    output ch2_ack,                     // Ack
    input ch2_eof,                      // No more channel 1 data avalaible

    // SI interface for trigger status
    input [DATA_WIDTH-1:0] tr_data,     // Data bus
    input tr_rdy,                       // Valid data in the bus
    output tr_ack,                      // Ack
    input tr_eof                        // No more channel 1 data avalaible
);

    parameter MAX_COUNT =  $rtoi($ceil($itor(DATA_WIDTH)/TX_WIDTH)) - 1;
    parameter COUNTER_BITS = (MAX_COUNT == 0) ? 1 : $clog2( MAX_COUNT );

    reg [COUNTER_BITS-1:0] cnt;

    // The state machine have two simple status.
    // It's on idle state when there is no data to send.
    // When one of the three input interfaces are ready, state changes to sending and source interface is stored.
    // When this interface indicates eof, status changes to IDLE.

    parameter ST_IDLE = 0;
    parameter ST_SENDING = 1;

    reg state;

    reg [1:0] source_interface;

    // 2D array packing input interfaces.
    reg [DATA_WIDTH-1:0] input_data [0:2];
    reg [0:2] input_rdy;
    reg [0:2] input_ack;
    reg [0:2] input_eof;


    always @* begin
        input_data[0] <= tr_data;
        input_data[1] <= ch1_data;
        input_data[2] <= ch2_data;

        input_rdy[0] <= tr_rdy;
        input_rdy[1] <= ch1_rdy;
        input_rdy[2] <= ch2_rdy;

        input_ack[0] <= tr_ack;
        input_ack[1] <= ch1_ack;
        input_ack[2] <= ch2_ack;

        input_eof[0] <= tr_eof;
        input_eof[1] <= ch1_eof;
        input_eof[2] <= ch2_eof;
    end

    always @( posedge(clk) ) begin
        if ( rst ) begin
            cnt <= MAX_COUNT;
            state <= ST_IDLE;
        end else begin
            if( ( state == ST_IDLE ) && ( |input_ack == 1'b1 ) ) begin
                state <= ST_SENDING;

                // A better way to write this ???
                if( input_ack[0] == 1'b1 ) begin
                    source_interface <= 0;
                end else begin
                    if( input_ack[1] == 1'b1 ) begin
                        source_interface <= 1;
                    end else begin
                        source_interface <= 2;
                    end
                end
            end

            if( ( state == ST_SENDING ) ) begin
                if( input_eof != 1'b1 ) begin
                    tx_data <= input_data[source_interface];
                    tx_rdy <= input_rdy[source_interface];
                    tx_ack <= input_ack[source_interface];
                end else begin
                    state <= ST_IDLE;
                end
            end
        end
    end
endmodule
