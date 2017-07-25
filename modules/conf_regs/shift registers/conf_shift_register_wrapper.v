
/*
    A module to send the data alocated in registers.
    When it receives a request to send the data (bit rqst_regs), it saves the current status of
    all of them in a shift register, and shifts 8 bits with every clock to sends all the bytes.

    NOTE: it has to access the entire matrix containing all the registers data.

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name                Modified by         Comment


    ToDo:
                Date            Suggested by    Priority    Activity                Description

    Releases:   In development ...
*/

`timescale 1ns/1ps

module conf_shift_register #(
    parameter NUM_REGS = 20,
    parameter DATA_WIDTH = 16,
    parameter TX_WIDTH = 8,
) (
    // Basic signals
    input clk,
    input rst,

    // Array of bits from Registers
    input [DATA_WIDTH * NUM_REGS-1:0] registers,
                          // registers      output      DATA_WIDTH * NUM_REGS (2D array)

    // Address and data simple interface
    input request,
    output tx_data[TX_WIDTH-1:0],
    output reg tx_rdy = 1'b0,

);

    localparam  SHIFT_COUNT = DATA_WIDTH * NUM_REGS / TX_WIDTH - 1;
    
    localparam  ST_INACTIVE = 0,
                ST_SENDING = 1;

    reg [DATA_WIDTH * NUM_REGS-1:0] shift_register = 0;
    reg [1:0] state = ST_INACTIVE;
    reg [15:0] counter = SHIFT_COUNT;
    
    assign tx_data = shift_register[TX_WIDTH-1:0];

    always @( posedge(clk) ) begin
        if ( rst == 1'b1 ) begin
            counter = SHIFT_COUNT;
        end else begin
            case (state)
                ST_INACTIVE:
                begin
                    if(request == 1'b1) begin
                        // Load registers data in shift register
                        shift_register <= registers;
                        // Enables output
                        tx_rdy <= 1'b1;
                        state <= ST_SENDING;
                    end                
                end
            
                ST_SENDING:
                begin
                    if(counter != 0) begin
                        // send next packet
                        shift_register = (shift_register >> TX_WIDTH);
                        counter <= counter - 1;
                    end else begin
                        // End
                        tx_rdy <= 1'b0;
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
