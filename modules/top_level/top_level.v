./*
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
    parameter ADDR_PRETRIGGER = `__ADDR_PRETRIGGER,
    parameter ADDR_NUM_SAMPLES = `__ADDR_NUM_SAMPLES,
    parameter ADDR_TRIGGER_VALUE = `__ADDR_TRIGGER_VALUE,
    parameter ADDR_TRIGGER_SETTINGS = `__ADDR_TRIGGER_SETTINGS,
    // default values

    // registers default values
    parameter DEFAULT_ADC_CLK_DIV_H = `__IV_DECIMATION_H,
    parameter DEFAULT_ADC_CLK_DIV_L = `__IV_DECIMATION_L,
    parameter DEFAULT_MOV_AVE_K_CH1 = `__IV_MOV_AVE_K_CH1,
    parameter DEFAULT_MOV_AVE_K_CH2 = `__IV_MOV_AVE_K_CH2,
    parameter DEFAULT_SETTINGS_CH1 = `__IV_CONF_CH1,
    parameter DEFAULT_SETTINGS_CH2 = `__IV_CONF_CH2,
    parameter DEFAULT_DAC_VALUE_CH1 = `__IV_DAC_CH1,
    parameter DEFAULT_DAC_VALUE_CH2 = `__IV_DAC_CH2,
    parameter DEFAULT_PRETRIGGER = `__IV_PRETRIGGER,
    parameter DEFAULT_NUM_SAMPLES = `__IV_NUM_SAMPLES,
    parameter DEFAULT_TRIGGER_VALUE = `__IV_TRIGGER_VALUE,
    parameter DEFAULT_TRIGGER_SETTINGS = `__IV_TRIGGER_SETTINGS
        // trigger_settings: source_sel(00,01,10,11), edge(pos/neg)
    //parameter DEFAULT_ADC_DF_DV_REG = (`__IV_DECIMATION_H << 16) | (`__IV_DECIMATION_L),

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
    wire rqst_trigger_status;

    // Tx Protocol
    wire [TX_DATA_WIDTH-1:0] tx_ch1_data;
    wire                tx_ch1_rdy;
    wire                tx_ch1_eof;
    wire                tx_ch1_ack;

    wire [TX_DATA_WIDTH-1:0] tx_ch2_data;
    wire                tx_ch2_rdy;
    wire                tx_ch2_eof;
    wire                tx_ch2_ack;

    wire [TX_DATA_WIDTH-1:0] tx_trigger_status_data;
    wire                tx_trigger_status_rdy;
    wire                tx_trigger_status_eof;
    wire                tx_trigger_status_ack;

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

    // Registers Rx Block
    registers_rx_block  #(
        .RX_DATA_WIDTH(),
        .REG_ADDR_WIDTH(),
        .REG_DATA_WIDTH()
    ) (
        .clk(clk_100M),
        .rst(rst),
        .rx_data(si_ft245_rx_data),
        .rx_rdy(si_ft245_rx_rdy),
        .rx_ack(si_ft245_rx_ack),
        .start_o(rqst_start),
        .stop_o(rqst_stop),
        .reset_o(rqst_reset),
        .rqst_ch1(rqst_ch1_data),
        .rqst_ch2(rqst_ch2_data),
        .rqst_trigger_status_o(rqst_trigger_status)/* ,
        .example_register_data() */
    );

    module trigger_block  #(
        .REG_ADDR_WIDTH(),
        .REG_DATA_WIDTH(),
        .BITS_DAC(),
        .BITS_ADC(),
        .ADDR_PRETRIGGER(),
        .ADDR_NUM_SAMPLES(),
        .ADDR_TRIGGER_VALUE(),
        .ADDR_TRIGGER_SETTINGS(),
        .DEFAULT_PRETRIGGER(),
        .DEFAULT_NUM_SAMPLES(),
        .DEFAULT_TRIGGER_VALUE(),
        .DEFAULT_TRIGGER_SETTINGS() // trigger_settings: source_sel(00,01,10,11), edge(pos/neg)
    ) (
        .clk(clk_100M),
        .rst(rst),
        // Request handler
        .start(rqst_start),
        .stop(rqst_stop),     // must be ORed with rqst_ch1 and rqst_ch2!!
        .rqst_trigger_status(rqst_trigger_status),
        // Tx Protocol
        .trigger_status_data(tx_trigger_status_data),
        .trigger_status_rdy(tx_trigger_status_rdy),
        .trigger_status_eof(tx_trigger_status_eof),
        .trigger_status_ack(tx_trigger_status_ack),
        // ADCs
        .ch1_in(ch1_adc_data),
        .ch2_in(ch2_adc_data),
        .ext_in(ext_trigger),
        .adc_ch1_rdy(ch1_adc_rdy),
        .adc_ch2_rdy(ch2_adc_rdy),
        // Ram Controller
        .we(we),
        // Registers bus
        .register_addr(reg_addr),
        .register_data(reg_data),
        .register_rdy(reg_rdy)
    );


    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,top_level);
            #1;
        end
    `endif

endmodule // adc_block
