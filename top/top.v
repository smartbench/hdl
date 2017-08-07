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

`include "conf_regs_defines.v"
`timescale 1ns/1ps

module top #(
    parameter BITS_ADC = 8,
    parameter BITS_DAC = 8
    parameter REG_ADDR_WIDTH = 4,
    parameter REG_DATA_WIDTH = 8
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

    fully_associative_register #(
        .ADDR_WIDTH     (REG_ADDR_WIDTH),
        .DATA_WIDTH     (REG_DATA_WIDTH),
        .MY_ADDR        (`ADDR_CHA_SETTINGS),
        .MY_RESET_VALUE (`DEFAULT_CHA_SETTINGS)
    ) reg_CHA_settings (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),

        // .data        ( { CHA_ATT , CHA_GAIN , CHA_DC_COUPLING , CHA_ON } )
        .data[7:5]      (CHA_ATT),
        .data[4:2]      (CHA_GAIN),
        .data[1]        (CHA_DC_COUPLING),
        .data[0]        (CHA_ON)
    );

    fully_associative_register #(
        .ADDR_WIDTH     (REG_ADDR_WIDTH),
        .DATA_WIDTH     (REG_DATA_WIDTH),
        .MY_ADDR        (`ADDR_CHB_SETTINGS),
        .MY_RESET_VALUE (`DEFAULT_CHB_SETTINGS)
    ) reg_CHB_settings (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),

        // .data        ( { CHA_ATT , CHA_GAIN , CHA_DC_COUPLING , CHA_ON } )
        .data[7:5]      (CHB_ATT),
        .data[4:2]      (CHB_GAIN),
        .data[1]        (CHB_DC_COUPLING),
        .data[0]        (CHB_ON)
    );

    

    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,top);
            #1;
        end
    `endif

endmodule
