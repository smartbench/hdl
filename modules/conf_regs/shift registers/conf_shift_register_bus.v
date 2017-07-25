
/*

The writing is controlled with the 'write enable' bit.
To know which address to write, it uses comparators.

The reading is triggered with the 'read enable' bit.
To read, it uses a shift register. It sweep the entire shift register (one address per clock)
The current address being read is in register_addr_r.

*/

`timescale 1ns/1ps

module conf_shift_register #(
    parameter NUM_REGS = 20,
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 16
) (
    // Basic signals
    input clk,
    input rst,

    // SI Interface (Write)
    input [ADDR_WIDTH-1:0] register_addr_w,
                                    // address                  input           ADDR_WIDTH (def. 8)
    input [DATA_WIDTH-1:0] register_data_w,
                                    // data                     input           DATA_WIDTH (def. 8)
    input write_enable,             // write enable              input           1

    // SI Interface (Read)
    input read_enable,              // request read
    output [ADDR_WIDTH-1:0] register_addr_r,
                                    // address                  input           ADDR_WIDTH (def. 8)
    output [DATA_WIDTH-1:0] register_data_r,
                                    // data                     output          DATA_WIDTH (def. 8)
    output reg read_available,            // data available           output          1

);

    localparam  ST_INACTIVE = 0,
                ST_SENDING = 1;

    // Registers
    reg [DATA_WIDTH-1:0] array_registers [0:NUM_REGS-1] = 0;
    
    // Shift Register
    reg [DATA_WIDTH * NUM_REGS-1:0] shift_register = 0;
    reg [ADDR_WIDTH-1:0] rd_addr_i = 0;
    
    // Current State of the FSM
    reg [1:0] state = ST_INACTIVE;
    
    // Lower bits of the shift register connected to the output port.
    assign register_data_r = shift_register[DATA_WIDTH-1:0];
    
    assign register_addr_r = rd_addr_i;

    // write with comparators, avoiding giant mux.
    // guácala ;)
    genvar c;
    generate
        for (c = 0; c < NUM_REGS; c = c + 1) begin:
            always @(posedge sysclk) begin
                if (rst == 1'b0 && write_enable == 1'b1 && register_addr_w == c) array_registers [c] <= register_data_w;
            end
        end
    endgenerate
    
    // 
    always @( posedge(clk) ) begin
        read_available <= 1'b0;
        if ( rst == 1'b1 ) begin
            // ...
        end else begin
            // ...
            case(state)
                ST_INACTIVE:
                begin
                    if(read_enable == 1'b1 && NUM_REGS != 0) begin  // the NUM_REGS condition simplifies in synthesis.
                        rd_addr_i <= 0;
                        read_available <= 1'b1;
                        state <= ST_READING;
                    end
                end

                ST_READING:
                begin
                    shift_register <= (shift_register >> DATA_WIDTH);
                    if(rd_addr_i != NUM_REGS-1) begin
                        rd_addr_i <= rd_addr_i + 1;
                    end else begin
                        read_available <= 1'b0;
                        state <= ST_INACTIVE;
                    end
                end
            endcase
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
