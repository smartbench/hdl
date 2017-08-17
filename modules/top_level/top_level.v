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
    parameter REG_DATA_WIDTH = `__REG_DATA_WIDTH,       // Simple Interface
    parameter REG_ADDR_WIDTH = `__REG_ADDR_WIDTH,
    parameter FT245_DATA_WIDTH = `__FT245_DATA_WIDTH,


    // registers addresses
    parameter ADDR_REQUESTS = `__ADDR_REQUESTS,
    parameter ADDR_ADC_CLK_DIV_CHA_L = `__ADDR_ADC_CLK_DIV_CHA_L,
    parameter ADDR_ADC_CLK_DIV_CHA_H = `__ADDR_ADC_CLK_DIV_CHA_H,
    parameter ADDR_ADC_CLK_DIV_CHB_L = `__ADDR_ADC_CLK_DIV_CHB_L,
    parameter ADDR_ADC_CLK_DIV_CHB_H = `__ADDR_ADC_CLK_DIV_CHB_H,
    parameter ADDR_N_MOVING_AVERAGE_CHA = `__ADDR_N_MOVING_AVERAGE_CHA,
    parameter ADDR_N_MOVING_AVERAGE_CHB = `__ADDR_N_MOVING_AVERAGE_CHB,
    parameter ADDR_SETTINGS_CHA = `__ADDR_SETTINGS_CHA,
    parameter ADDR_SETTINGS_CHB = `__ADDR_SETTINGS_CHB,
    parameter ADDR_DAC_CHA = `__ADDR_DAC_CHA,
    parameter ADDR_DAC_CHB = `__ADDR_DAC_CHB,
    parameter ADDR_PRETRIGGER = `__ADDR_PRETRIGGER,
    parameter ADDR_NUM_SAMPLES = `__ADDR_NUM_SAMPLES,
    parameter ADDR_TRIGGER_VALUE = `__ADDR_TRIGGER_VALUE,
    parameter ADDR_TRIGGER_SETTINGS = `__ADDR_TRIGGER_SETTINGS,
    // default values

    // registers default values
    parameter DEFAULT_ADC_CLK_DIV_CHA_H = `__IV_ADC_CLK_DIV_CHA_H,
    parameter DEFAULT_ADC_CLK_DIV_CHA_L = `__IV_ADC_CLK_DIV_CHA_L,
    parameter DEFAULT_ADC_CLK_DIV_CHB_H = `__IV_ADC_CLK_DIV_CHB_H,
    parameter DEFAULT_ADC_CLK_DIV_CHB_L = `__IV_ADC_CLK_DIV_CHB_L,
    parameter DEFAULT_N_MOVING_AVERAGE_CHA = `__IV_N_MOVING_AVERAGE_CHA,
    parameter DEFAULT_N_MOVING_AVERAGE_CHB = `__IV_N_MOVING_AVERAGE_CHB,
    parameter DEFAULT_SETTINGS_CHA = `__IV_CONF_CHA,
    parameter DEFAULT_SETTINGS_CHB = `__IV_CONF_CHB,
    parameter DEFAULT_DAC_CHA = `__IV_DAC_CHA,
    parameter DEFAULT_DAC_CHB = `__IV_DAC_CHB,
    parameter DEFAULT_PRETRIGGER = `__IV_PRETRIGGER,
    parameter DEFAULT_NUM_SAMPLES = `__IV_NUM_SAMPLES,
    parameter DEFAULT_TRIGGER_VALUE = `__IV_TRIGGER_VALUE,
    parameter DEFAULT_TRIGGER_SETTINGS = `__IV_TRIGGER_SETTINGS
        // trigger_settings: source_sel(00,01,10,11), edge(pos/neg)
    //parameter DEFAULT_ADC_DF_DV_REG = (`__IV_ADC_CLK_DIV_H << 16) | (`__IV_ADC_CLK_DIV_L),

    //
    parameter ADC_DF_WIDTH   = `__ADC_DF_WIDTH,     // ADC decimation
    parameter MA_ACUM_WIDTH = `__MA_ACUM_WIDTH      // Moving Average Acumulator
  )(
    // Basic
    input clk_i,
    input rst,

    // Channel 1 - ADC
    input [BITS_ADC-1:0] chA_adc_in,
    output chA_adc_oe,
    output chA_adc_clk_o,
    // Channel 1 - Analog
    output [2:0] chA_gain_sel,
    output [2:0] chA_att_sel,
    output chA_dc_coupling_sel,
    //output chA_enabled_sel,


    // Channel 2 - ADC
    input [BITS_ADC-1:0] chB_adc_in,
    output chB_adc_oe,
    output chB_adc_clk_o,
    // Channel 2 - Analog
    output [2:0] chA_gain_sel,
    output [2:0] chA_att_sel,
    output chA_dc_coupling_sel,
    output chA_enabled_sel,

    // Ext
    input ext_trigger,

    // FT245 interface
    inout [FT245_DATA_WIDTH-1:0] in_out_245,
    input rxf_245,
    output rx_245,
    input txe_245,
    output wr_245,

    // I2C
    inout SDA,
    inout SCL

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
    wire rqst_chA_data;
    wire rqst_chB_data;
    wire rqst_trigger_status;

    // Tx Protocol
    wire [TX_DATA_WIDTH-1:0] tx_chA_data;
    wire                tx_chA_rdy;
    wire                tx_chA_eof;
    wire                tx_chA_ack;

    wire [TX_DATA_WIDTH-1:0] tx_chB_data;
    wire                tx_chB_rdy;
    wire                tx_chB_eof;
    wire                tx_chB_ack;

    wire [TX_DATA_WIDTH-1:0] tx_trigger_status_data;
    wire                tx_trigger_status_rdy;
    wire                tx_trigger_status_eof;
    wire                tx_trigger_status_ack;

    // Data from adc_block
    wire [BITS_ADC-1:0] chA_adc_data;
    wire                chA_adc_rdy;

    wire [BITS_ADC-1:0] chB_adc_data;
    wire                chB_adc_rdy;

    // Buffer Controller <--> RAM
    wire we;
    wire [REG_DATA_WIDTH-1:0] num_samples;

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
        .RX_DATA_WIDTH(RX_DATA_WIDTH),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .REG_DATA_WIDTH(REG_DATA_WIDTH)
    ) rx_block_u (
        .clk(clk_100M),
        .rst(rst),
        .rx_data(si_ft245_rx_data),
        .rx_rdy(si_ft245_rx_rdy),
        .rx_ack(si_ft245_rx_ack),
        .start_o(rqst_start),
        .stop_o(rqst_stop),
        .reset_o(rqst_reset),
        .rqst_ch1(rqst_chA_data),
        .rqst_ch2(rqst_chB_data),
        .rqst_trigger_status_o(rqst_trigger_status)/* ,
        .example_register_data() */
    );

    trigger_block  #(
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .REG_DATA_WIDTH(REG_DATA_WIDTH),
        .BITS_DAC(BITS_DAC),
        .BITS_ADC(BITS_ADC),
        .ADDR_PRETRIGGER(ADDR_PRETRIGGER),
        .ADDR_NUM_SAMPLES(ADDR_NUM_SAMPLES),
        .ADDR_TRIGGER_VALUE(ADDR_TRIGGER_VALUE),
        .ADDR_TRIGGER_SETTINGS(ADDR_TRIGGER_SETTINGS),
        .DEFAULT_PRETRIGGER(DEFAULT_PRETRIGGER),
        .DEFAULT_NUM_SAMPLES(DEFAULT_NUM_SAMPLES),
        .DEFAULT_TRIGGER_VALUE(DEFAULT_TRIGGER_VALUE),
        .DEFAULT_TRIGGER_SETTINGS(DEFAULT_TRIGGER_SETTINGS) // trigger_settings: source_sel(00,01,10,11), edge(pos/neg)
    ) trigger_block_u (
        .clk(clk_100M),
        .rst(rst),
        // Request handler
        .start(rqst_start),
        .stop(rqst_stop),     // must be ORed with rqst_chA and rqst_chB!!
        .rqst_trigger_status(rqst_trigger_status),
        // Tx Protocol
        .trigger_status_data(tx_trigger_status_data),
        .trigger_status_rdy(tx_trigger_status_rdy),
        .trigger_status_eof(tx_trigger_status_eof),
        .trigger_status_ack(tx_trigger_status_ack),
        // ADCs
        .ch1_in(chA_adc_data),
        .ch2_in(chB_adc_data),
        .ext_in(ext_trigger),
        .adc_ch1_rdy(chA_adc_rdy),
        .adc_ch2_rdy(chB_adc_rdy),
        // Ram Controller
        .we(we),
        // Registers bus
        .register_addr(reg_addr),
        .register_data(reg_data),
        .register_rdy(reg_rdy),
        // num samples value
        .num_samples_o(num_samples)
    );

    tx_protocol #(
        .DATA_WIDTH(TX_DATA_WIDTH),
        .TX_WIDTH(TX_DATA_WIDTH),
        .SOURCES(3)
    ) tx_protocol_u (
        .clk(clk_100M),
        .rst(rst),
        // SI - Output (FT245)
        .tx_data(si_ft245_tx_data),
        .tx_rdy(si_ft245_tx_rdy),
        .tx_ack(si_ft245_tx_ack),
        // SI - Channel 1
        .ch1_data(tx_chA_data),
        .ch1_rdy(tx_chA_rdy),
        .ch1_eof(tx_chA_eof),
        ch1_ack(tx_chA_ack),
        // SI - Channel 2
        .ch2_data(tx_chB_data),
        .ch2_rdy(tx_chB_rdy),
        .ch2_eof(tx_chB_eof),
        ch2_ack(tx_chB_ack),
        // SI - Trigger status
        .trig_data(tx_trigger_status_data),
        .trig_rdy(tx_trigger_status_rdy),
        .trig_eof(tx_trigger_status_eof),
        trig_ack(tx_trigger_status_ack)
    );

    /*
    // FT245
    ft245_interface #(
        .CLOCK_PERIOD_NS(10)
    )(
        .clk(clk_100M),
        .rst(rst),
        // ft245 rx interface
        .rx_data_245(rx_data_245),
        .rxf_245(rxf_245),
        .rx_245(rx_245),
        // ft245 tx interface
        .tx_data_245(tx_data_245),
        .txe_245(txe_245),
        .wr_245(wr_245),
        .tx_oe_245(tx_oe_245),
        // simple interface
        .rx_data_si(si_ft245_rx_data),
        .rx_rdy_si(si_ft245_rx_rdy),
        .rx_ack_si(si_ft245_rx_ack),
        .tx_data_si(si_ft245_tx_data),
        .tx_rdy_si(si_ft245_tx_rdy),
        .tx_ack_si(si_ft245_tx_ack)
    );*/
    ft245_block #(
        .FT245_WIDTH(`FT245_WIDTH),
        .CLOCK_PERIOD_NS(10)
    ) ft245_block_u (
        .clk(clk_100M),
        .rst(rst),
        .in_out_245(in_out_245),
        .rxf_245(rxf_245),
        .rx_245(rx_245),
        .txe_245(txe_245),
        .wr_245(wr_245),
        .rx_data_si(si_ft245_rx_data),
        .rx_rdy_si(si_ft245_rx_rdy),
        .rx_ack_si(si_ft245_rx_ack),
        .tx_data_si(si_ft245_tx_data),
        .tx_rdy_si(si_ft245_tx_rdy),
        .tx_ack_si(si_ft245_tx_ack)

    );

    // Channel Block
    channel_block #(
        .BITS_ADC(BITS_ADC),
        .BITS_DAC(BITS_DAC),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .REG_DATA_WIDTH(REG_DATA_WIDTH),
        .TX_DATA_WIDTH(TX_DATA_WIDTH),
        .RAM_DATA_WIDTH(RAM_DATA_WIDTH),
        .RAM_SIZE(RAM_SIZE),
        .ADDR_CH_SETTINGS(ADDR_SETTINGS_CHA),
        .ADDR_DAC_VALUE(ADDR_DAC_CHA),
        .DEFAULT_CH_SETTINGS(DEFAULT_SETTINGS_CHA),
        .DEFAULT_DAC_VALUE(DEFAULT_DAC_CHA)
    ) channel_block_A(
        clk(clk_100M),
        rst(rst),
        // iInterface with ADC pins
        adc_input(chA_adc_in),
        adc_oe(chA_adc_oe),
        adc_clk_o(chA_adc_clk_o),
        // Interface with MUXes
        Att_Sel(chA_att_sel),
        Gain_Sel(chA_gain_sel),
        DC_Coupling(chA_dc_coupling_sel),
        // ChannelOn
        // Buffer Controller
        .rqst_data(rqst_chA_data),
        .we(we),
        .num_samples(num_samples),
        // Registers Bus
        .register_addr(reg_addr),
        .register_data(reg_data),
        .reg_rdy(reg_rdy),
        // Trigger source
        .adc_data_o(chA_adc_data),
        .adc_rdy_o(chA_adc_rdy),
        // Tx Protocol
        .tx_data(tx_chA_data),
        .tx_rdy(tx_chA_rdy),
        .tx_eof(tx_chA_eof),
        .tx_ack(tx_chA_ack)
    );

    // Channel Block
    channel_block #(
        .BITS_ADC(BITS_ADC),
        .BITS_DAC(BITS_DAC),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .REG_DATA_WIDTH(REG_DATA_WIDTH),
        .TX_DATA_WIDTH(TX_DATA_WIDTH),
        .RAM_DATA_WIDTH(RAM_DATA_WIDTH),
        .RAM_SIZE(RAM_SIZE),
        .ADDR_CH_SETTINGS(ADDR_SETTINGS_CHB),
        .ADDR_DAC_VALUE(ADDR_DAC_CHB),
        .DEFAULT_CH_SETTINGS(DEFAULT_SETTINGS_CHB),
        .DEFAULT_DAC_VALUE(DEFAULT_DAC_CHB)
    ) channel_block_B(
        clk(clk_100M),
        rst(rst),
        // iInterface with ADC pins
        adc_input(chB_adc_in),
        adc_oe(chB_adc_oe),
        adc_clk_o(chB_adc_clk_o),
        // Interface with MUXes
        Att_Sel(chB_att_sel),
        Gain_Sel(chB_gain_sel),
        DC_Coupling(chB_dc_coupling_sel),
        // ChannelOn
        // Buffer Controller
        .rqst_data(rqst_chB_data),
        .we(we),
        .num_samples(num_samples),
        // Registers Bus
        .register_addr(reg_addr),
        .register_data(reg_data),
        .reg_rdy(reg_rdy),
        // Trigger source
        .adc_data_o(chB_adc_data),
        .adc_rdy_o(chB_adc_rdy),
        // Tx Protocol
        .tx_data(tx_chB_data),
        .tx_rdy(tx_chB_rdy),
        .tx_eof(tx_chB_eof),
        .tx_ack(tx_chB_ack)
    );

    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,top_level);
            #1;
        end
    `endif

endmodule // adc_block
