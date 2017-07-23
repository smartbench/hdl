

/*
    Configuration Registers Module

    This module contains the configuration registers.
    These registers are loaded with the Simple Interface

    ADC1175 timing diagrams and other data in:
                        http://www.ti.com/lit/ds/symlink/adc1175.pdf

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name            Modified by     Comment
                2017/07/23      0.1             first_approach AK               Starting development...

    ToDo:
                Date            Suggested by    Priority    Activity                Description

    Releases:   In development ...
*/

`timescale 1ns/1ps

module conf_regs  (
                                // Description                  Type            Width
    // Basic
    input clk,                  // fpga clock                   input           1
    input rst,                  // synch reset                  input           1

    // SI Interface
    input register_addr,        // address                      input           ADDR_WIDTH (def. 8)
    input register_data,        // data                         input           DATA_WIDTH (def. 8)
    input register_rdy,         // data ready                   output          1
    output register_ack,        // Acknowledge

    // muxes and switches
    output [2:0] CHA_ATT,
    output [2:0] CHA_GAIN,
    output CHA_DC_COUPLING,
    output [2:0]CHB_ATT,
    output [2:0]CHB_GAIN,
    output CHB_DC_COUPLING,

    // DAC Simple Interface
    output [7:0] ch1_dac_value,     // DAC value
    output [7:0] ch2_dac_value,     // DAC value
    output reg dac_changed,         // new value must be sent to DAC
    //output SDA,
    //output SCL,

    output [7:0] trigger_value,
    output [15:0] num_samples,
    output [15:0] pre_trigger,
    output [1:0] trigger_source,
    output trigger_edge,
    output trigger_conf,

    output reg start,
    /*output ,
    output ,
    output ,*/

);

    integer addr_i;
    assign addr_i = register_addr;

    // Parameters
    parameter DATA_WIDTH = 16;  // Registers data width
    parameter ADDR_WIDTH = 16;  // Address data width
    parameter NUM_REGS = 20;

    // registers
    /*  Address     Data
        0x0000      { CHA_ATT[2:0] , CHA_GAIN[2:0] , CHA_DC_COUPLING , ___ , CHB_ATT[2:0] , CHB_GAIN[2:0] , CHB_DC_COUPLING, ___ }
        0x0001      { CHA_OFFSET[7:0] ,  CHB_OFFSET[7:0]}
        0x0002      { trigger_value[7:0] , trigger_edge , trigger_conf , trigger_source[1:0] , ___ , ___ , ___ , ___ }
        0x0003      { num_samples[15:0] }
        0x0004      { pre_trigger[15:0] }
        0x0005      { decimation_factor_low[15:0] }
        0x0006      { decimation_factor_high[15:0] }
        0x0007
        0x0008

    */
    reg [DATA_WIDTH-1:0] registers [0:NUM_REGS-1];

    localparam  ADDR_ANALOG = 0;
    localparam  ADDR_DAC = 1;
    localparam  ADDR_TRIGGER = 2;
    localparam  ADDR_NUM_SAMPLES = 3;
    localparam  ADDR_PRE_TRIGGER = 4;
    localparam  ADDR_DECIMATION_L = 5;
    localparam  ADDR_DECIMATION_H = 6;
    localparam  ADDR_START = 16;

    // Addr 0x0000
    assign CHA_ATT [2:0]    = registers[ADDR_ANALOG][15:13];
    assign CHA_GAIN [2:0]   = registers[ADDR_ANALOG][12:10];
    assign CHA_DC_COUPLING  = registers[ADDR_ANALOG][9];

    assign CHB_ATT [2:0]    = registers[ADDR_ANALOG][7:5];
    assign CHB_GAIN [2:0]   = registers[ADDR_ANALOG][4:2];
    assign CHB_DC_COUPLING  = registers[ADDR_ANALOG][1];

    // Addr 0x0001
    assign ch1_dac_value [7:0] = registers[ADDR_DAC][15:8];
    assign ch2_dac_value [7:0] = registers[ADDR_DAC][7:0];

    // Addr 0x0002
    assign trigger_value [7:0]  = registers[ADDR_TRIGGER][15:8];
    assign trigger_conf         = registers[ADDR_TRIGGER][7];
    assign trigger_edge         = registers[ADDR_TRIGGER][6];
    assign trigger_source [1:0] = registers[ADDR_TRIGGER][5:4];

    // Addr 0x0003
    assign num_samples [15:0]   = registers[ADDR_NUM_SAMPLES][15:0];

    // Addr 0x0004
    assign pre_trigger [15:0]   = registers[ADDR_PRE_TRIGGER][15:0];

    // Addr 0x0005 and 0x0006
    assign decimation_factor[31:16] = registers[ADDR_DECIMATION_H][15:0];
    assign decimation_factor[15:00] = registers[ADDR_DECIMATION_L][15:0];


    always @(posedge clk_i) begin
        register_ack <= 1'b0;
        dac_changed <= 1'b0;
        start <= 1'b0;
        if (reset == 1'b1) begin                                            // RESET
            // Default values
            registers[ADDR_ANALOG] <= 16'd0;
            registers[ADDR_DAC] <= 16'h8080;
            registers[ADDR_TRIGGER] <= 16'h8010;
            registers[ADDR_NUM_SAMPLES] <= 16'd1024;
            registers[ADDR_PRE_TRIGGER] <= 16'd512;
            registers[ADDR_DECIMATION_H] <= 16'd0;
            registers[ADDR_DECIMATION_L] <= 16'd4;

        end else begin

            if (register_rdy == 1'b1) begin
                if (addr_i < NUM_REGS) begin
                    register_ack <= 1'b1;
                    if (addr_i == ADDR_START) begin
                        start <= 1'b1;              // start signal
                    end else begin
                        registers[addr_i] [DATA_WIDTH-1:0] <= register_data;
                        register_ack <= 1'b1;
                    end
                    if(addr_i == ADDR_DAC_CH1) dac_changed <= 1'b1;
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
