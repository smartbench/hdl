/*
    Top level insatantiating all register related modules.

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name                Modified by         Comment
                2017/07/28      0.1             REG_INTEGRATION     IP                  conf_regs+conf_shift_register+conf_reg_wrapper

    ToDo:
                Date            Suggested by    Priority    Activity                Description
                2017/07/28      IP              Moderate    Add a request reg       Instantiation of a request reg and realization of testbench.
                2017/07/28      IP              Moderate    Synthesis               Try to synthesize. Test it in ice40hx8k using configuration_registers_rx and uart modules.

    Releases:   In development ...
*/

`ifdef COCOTB_SIM
    `define COCOTB_SIB_TOP
    `undef COCOTB_SIM                           // We don´t want included modules to create a dumpfile
`endif

`define PARENT_DIR
`include "../conf_regs.v"
`include "../conf_reg_wrapper.v"
`include "../conf_shift_register.v"
`include "../conf_regs_defines.v"


`ifdef COCOTB_SIB_TOP
    `define COCOTB_SIM
`endif

`timescale 1ns/1ps

module top #(
    parameter BITS_ADC = 8,
    parameter BITS_DAC = 8
)   (
                                    // Description                  Type            Width
    // Basic
    input clk,                      // fpga clock               input           1
    input rst,                      // synch reset              input           1

    // Address and data, write SI interface
    input [`__ADDR_WIDTH-1:0] register_addr,
                                    // address                  input           ADDR_WIDTH (def. 8)
    input [`__DATA_WIDTH-1:0] register_data,
                                    // data                     input           DATA_WIDTH (def. 8)
    input register_rdy,             // data ready               input           1
    output register_ack,            // Acknowledge              output          1

    // Address and data, tx simple interface
    input request,                  // This bit loads the current array in the shift register
    input ack,                      // This bit forces a shift: >> TX_WIDTH
    output [`__TX_WIDTH-1:0] tx_data,  // This is wired to the TX_WIDTH lowest bits of the shift register
    output empty,        // This notifies when all the data was already shifted.

    // REGISTERS
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
    wire [`__DATA_WIDTH * `__NUM_REGS-1:0] registers;

    conf_regs configuration_registers (
        .clk                    (clk)                   ,
        .rst                    (rst)                   ,
        .register_addr          (register_addr)         ,
        .register_data          (register_data)         ,
        .register_rdy           (register_rdy)          ,
        .register_ack           (register_ack)          ,
        .registers              (registers)
    );

    conf_shift_register shift_register (
        .clk                    (clk)                   ,
        .rst                    (rst)                   ,
        .registers              (registers)             ,
        .request                (request)               ,
        .ack                    (ack)                   ,
        .tx_data                (tx_data)               ,
        .empty                  (empty)
    );

    conf_reg_wrapper wrapper (
        .registers              (registers)             ,
        .CHA_ATT                (CHA_ATT)               ,
        .CHA_GAIN               (CHA_GAIN)              ,
        .CHA_DC_COUPLING        (CHA_DC_COUPLING)       ,
        .CHA_ON                 (CHA_ON)                ,
        .CHB_ATT                (CHB_ATT)               ,
        .CHB_GAIN               (CHB_GAIN)              ,
        .CHB_DC_COUPLING        (CHB_DC_COUPLING)       ,
        .CHB_ON                 (CHB_ON)                ,
        .decimation_factor      (decimation_factor)     ,
        .ch1_dac_value          (ch1_dac_value)         ,
        .ch2_dac_value          (ch2_dac_value)         ,
        .num_samples            (num_samples)           ,
        .pre_trigger            (pre_trigger)           ,
        .trigger_mode           (trigger_mode)          ,
        .trigger_value          (trigger_value)         ,
        .trigger_edge           (trigger_edge)          ,
        .trigger_source_sel     (trigger_source_sel)
    );

    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,top);
            #1;
        end
    `endif

endmodule
