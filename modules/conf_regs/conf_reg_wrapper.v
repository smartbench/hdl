

/*
    Configuration Registers Wrapper Module

    This module connencts the bit array of the configuration registers with Named easily identifiable nets.
    Only wires here!

*/

`include "conf_regs_defines.v"

`timescale 1ns/1ps

module conf_reg_wrapper  #(
    parameter ADDR_WIDTH = `__ADDR_WIDTH,
    parameter DATA_WIDTH = `__DATA_WIDTH,
    parameter NUM_REGS = `__NUM_REGS ,
    parameter BITS_DAC = 8,
    parameter BITS_ADC = 8
) (
                                // Description                  Type            Width
    // No clock here...

    // registers
    input [DATA_WIDTH * NUM_REGS-1:0] registers,
                                // registers data

    // Analog Muxes and Switches
    output [2:0] CHA_ATT,
    output [2:0] CHA_GAIN,
    output CHA_DC_COUPLING,
    output CHA_ON,
    output [2:0]CHB_ATT,
    output [2:0]CHB_GAIN,
    output CHB_DC_COUPLING,
    output CHB_ON,

    // ADC decimation_factor
    output [31:0] decimation_factor,

    // DACs
    output [BITS_DAC-1:0] ch1_dac_value,     // DAC value
    output [BITS_DAC-1:0] ch2_dac_value,     // DAC value

    // Buffer Controller
    output [15:0] num_samples,
    output [15:0] pre_trigger,
    output trigger_mode,

    // Trigger Input Selector
    output [BITS_ADC-1:0] trigger_value,
    output trigger_edge,
    output [1:0] trigger_source_sel
);

    // Reads registers as a 2D matrix to perform a less confusing assignation.
    wire [DATA_WIDTH-1:0] array_registers [0:NUM_REGS-1];
    genvar h;
    generate
        for(h = 0 ; h < NUM_REGS ; h = h + 1)
            assign array_registers [h] [DATA_WIDTH-1:0] = registers [ (h + 1) * DATA_WIDTH - 1  : h * DATA_WIDTH ] ;
    endgenerate

    // Addr 0x0000 (REQUESTS)
    // LEAVE ADDRESS 0x0000 EMPTY!

    // Addr 0x0001
    assign CHA_ATT [2:0]    = array_registers[`__ADDR_CONF_CH1][`__CONF_CH_ATT];
    assign CHA_GAIN [2:0]   = array_registers[`__ADDR_CONF_CH1][`__CONF_CH_GAIN];
    assign CHA_DC_COUPLING  = array_registers[`__ADDR_CONF_CH1][`__CONF_CH_DC_COUPLING];
    assign CHA_ON           = array_registers[`__ADDR_CONF_CH1][`__CONF_CH_ON];

    // Addr 0x0002
    assign CHB_ATT [2:0]    = array_registers[`__ADDR_CONF_CH2][`__CONF_CH_ATT];
    assign CHB_GAIN [2:0]   = array_registers[`__ADDR_CONF_CH2][`__CONF_CH_GAIN];
    assign CHB_DC_COUPLING  = array_registers[`__ADDR_CONF_CH2][`__CONF_CH_DC_COUPLING];
    assign CHB_ON           = array_registers[`__ADDR_CONF_CH2][`__CONF_CH_ON];

    // Addr 0x0003
    assign ch1_dac_value [BITS_DAC-1:0] = array_registers[`__ADDR_DAC_CH1][BITS_DAC-1:0];

    // Addr 0x0004
    assign ch2_dac_value [BITS_DAC-1:0] = array_registers[`__ADDR_DAC_CH2][BITS_DAC-1:0];

    // Addr 0x0005
    assign trigger_mode         = array_registers[`__ADDR_TRIGGER_CONF][`__TRIGGER_CONF_MODE];
    assign trigger_edge         = array_registers[`__ADDR_TRIGGER_CONF][`__TRIGGER_CONF_EDGE];
    assign trigger_source_sel [1:0] = array_registers[`__ADDR_TRIGGER_CONF][`__TRIGGER_CONF_SOURCE_SEL];

    // Addr 0x0006
    assign trigger_value [BITS_ADC-1:0]  = array_registers[`__ADDR_TRIGGER_VALUE][BITS_ADC-1:0];

    // Addr 0x0007
    assign num_samples [15:0]   = array_registers[`__ADDR_NUM_SAMPLES][15:0];

    // Addr 0x0008
    assign pre_trigger [15:0]   = array_registers[`__ADDR_PRE_TRIGGER][15:0];

    // Addr 0x0009 and 0x000A
    assign decimation_factor[31:16] = array_registers[`__ADDR_DECIMATION_H][15:0];
    assign decimation_factor[15:00] = array_registers[`__ADDR_DECIMATION_L][15:0];

    `ifdef COCOTB_SIM       // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,conf_reg_wrapper);
            #1;
        end
    `endif

endmodule
