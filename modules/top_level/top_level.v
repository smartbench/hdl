/*
    Top Level

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name                Modified by         Comment



    ToDo:
                Date            Suggested by    Priority    Activity                Description

    Releases:
*/

`include "conf_regs_defines.v"

`timescale 1ns/1ps

module top_level #(
    parameter BITS_ADC = `__BITS_ADC,
    parameter BITS_DAC = `__BITS_DAC,
    parameter RAM_DATA_WIDTH = `__BITS_ADC,
    parameter RAM_SIZE = `__RAM_SIZE_CH,
    parameter TX_DATA_WIDTH = `__TX_WIDTH,
    parameter RX_DATA_WIDTH = `__RX_WIDTH,
    parameter REG_DATA_WIDTH = `__DATA_WIDTH,       // Simple Interface
    parameter REG_ADDR_WIDTH = `__ADDR_WIDTH,

    // registers addresses
    parameter ADDR_ADC_CLK_DIV_L = `__ADDR_ADC_CLK_DIV_L,
    parameter ADDR_ADC_CLK_DIV_H = `__ADDR_ADC_CLK_DIV_H,
    parameter ADDR_MOV_AVE_K_CH1 = `__ADDR_MOV_AVE_K_CH1,
    parameter ADDR_MOV_AVE_K_CH2 = `__ADDR_MOV_AVE_K_CH2,
    parameter ADDR_SETTINGS_CH1 = `__ADDR_CONF_CH1,
    parameter ADDR_SETTINGS_CH2 = `__ADDR_CONF_CH2,
    parameter ADDR_DAC_VALUE_CH1 = `__ADDR_DAC_CH1,
    parameter ADDR_DAC_VALUE_CH2 = `__ADDR_DAC_CH2,

    // registers default values
    parameter DEFAULT_ADC_CLK_DIV_H = `__IV_DECIMATION_H,
    parameter DEFAULT_ADC_CLK_DIV_L = `__IV_DECIMATION_L,
    parameter DEFAULT_MOV_AVE_K_CH1 = `__IV_MOV_AVE_K_CH1,
    parameter DEFAULT_MOV_AVE_K_CH2 = `__IV_MOV_AVE_K_CH2,
    //parameter DEFAULT_ADC_DF_DV_REG = (`__IV_DECIMATION_H << 16) | (`__IV_DECIMATION_L),
    parameter DEFAULT_SETTINGS_CH1 = `__IV_CONF_CH1,
    parameter DEFAULT_SETTINGS_CH2 = `__IV_CONF_CH2,
    parameter DEFAULT_DAC_VALUE_CH1 = `__IV_DAC_CH1,
    parameter DEFAULT_DAC_VALUE_CH2 = `__IV_DAC_CH2,

    //
    parameter ADC_DF_WIDTH   = `__ADC_DF_WIDTH,     // ADC decimation
    parameter MA_ACUM_WIDTH = `__MA_ACUM_WIDTH      // Moving Average Acumulator
  )(
    // Basic
    input clk_i,
    input rst,

    // Channel 1 - ADC
    input [BITS_ADC-1:0] ch1_adc_in,
    output ch1_adc_oe,
    output ch1_adc_clk_o,
    // Channel 1 - Analog
    output [2:0] ch1_gain_sel,
    output [2:0] ch1_att_sel,
    output ch1_dc_coupling_sel,
    output ch1_enabled_sel,


    // Channel 2 - ADC
    input [BITS_ADC-1:0] ch2_adc_in,
    output ch2_adc_oe,
    output ch2_adc_clk_o,
    // Channel 2 - Analog
    output [2:0] ch1_gain_sel,
    output [2:0] ch1_att_sel,
    output ch1_dc_coupling_sel,
    output ch1_enabled_sel,

    // Ext
    input ext_trigger,

    // FTDI
    // ...

    // I2C
    output SDA,
    output SCL

);

    // PLL output clock
    wire clk_100M;

    // Registers bus
    wire [REG_ADDR_WIDTH-1:0] reg_addr;
    wire [REG_DATA_WIDTH-1:0] reg_data;
    wire reg_rdy;

    // FT245 SI
    wire [RX_WIDTH-1:0] si_ft245_rx_data;
    wire                si_ft245_rx_rdy;
    wire                si_ft245_rx_ack;

    wire [TX_WIDTH-1:0] si_ft245_tx_data;
    wire                si_ft245_tx_rdy;
    wire                si_ft245_tx_ack;

    // Requests signals
    wire rqst_start;
    wire rqst_stop;
    wire rqst_reset;
    wire rqst_ch1_data;
    wire rqst_ch2_data;

    // Tx Protocol
    wire [TX_DATA_WIDTH-1:0] tx_ch1_data;
    wire                tx_ch1_rdy;
    wire                tx_ch1_eof;
    wire                tx_ch1_ack;

    wire [TX_DATA_WIDTH-1:0] tx_ch2_data;
    wire                tx_ch2_rdy;
    wire                tx_ch2_eof;
    wire                tx_ch2_ack;

    // Data from adc_block
    wire [BITS_ADC-1:0] ch1_adc_data;
    wire                ch1_adc_rdy;

    wire [BITS_ADC-1:0] ch2_adc_data;
    wire                ch2_adc_rdy;

    // Buffer Controller <--> RAM
    wire we;

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



    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,top_level);
            #1;
        end
    `endif

endmodule // adc_block
