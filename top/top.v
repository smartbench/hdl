/*
    Top level

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name                Modified by         Comment
                2017/07/28      0.1             REG_INTEGRATION     IP                  conf_regs+conf_shift_register+conf_reg_wrapper
                2017/08/07      0.2             REGS DELETED        AK                  Regs are instantiated in the module they are used,
                                                                                            and the writing is done with a bus composed of data, addr and rdy.
                                                                                            PLL Instantiated

    ToDo:
                Date            Suggested by    Priority    Activity                Description


    Releases:   In development ...
*/

`include "conf_regs_defines.v"
`timescale 1ns/1ps

module top #(
    parameter BITS_ADC = `__BITS_ADC,
    parameter BITS_DAC = `__BITS_DAC,
    parameter REG_ADDR_WIDTH = `__REG_ADDR_WIDTH,
    parameter REG_DATA_WIDTH = `__REG_DATA_WIDTH
)   (
                                    // Description                  Type            Width
    // Basic
    input clock_i,                  // fpga clock               input           1
    input rst,                      // synch reset              input           1

    // ADC
    input [BITS_ADC-1:0] ch1_adc_data,
    input [BITS_ADC-1:0] ch2_adc_data,
    output adc_ch1_clk_o,
    output adc_ch2_clk_o,

    // Analog
    output [2:0] ch1_gain_sel,
    output [2:0] ch2_gain_sel,
    output [2:0] ch1_att_sel,
    output [2:0] ch2_att_sel,
    output ch1_dc_coupling,
    output ch2_dc_coupling,

    // I2C (dacs)
    output i2c_sda,
    output i2c_scl,

    // LEDS (for testing)
    output led_o_0;
    output led_o_1;
    output led_o_2;
    output led_o_3;
    output led_o_4;
    output led_o_5;
    output led_o_6;
    output led_o_7;

);

    // PLL output clock
    wire clk_100M;

    wire [REG_ADDR_WIDTH-1:0] reg_addr;
    wire [REG_DATA_WIDTH-1:0] reg_data;
    wire reg_rdy;

    // PLL instantiation
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0000),
        .DIVF(7'b1000010),
        .DIVQ(3'b011),
        .FILTER_RANGE(3'b001)
    )uut(
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clock_i),
        .PLLOUTCORE(clk_100M)
    );


    // LEDS assigned to counter for testing
    wire [7:0] s_Q;
    assign led_o_7 = s_Q[7];
    assign led_o_6 = s_Q[6];
    assign led_o_5 = s_Q[5];
    assign led_o_4 = s_Q[4];
    assign led_o_3 = s_Q[3];
    assign led_o_2 = s_Q[2];
    assign led_o_1 = s_Q[1];
    assign led_o_0 = s_Q[0];

    counter u1(
        .clk(clk_100M),
        .Q(s_Q)
    );

    `ifdef COCOTB_SIM          // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,top);
            #1;
        end
    `endif

endmodule
