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


//`define TESTING_ECHO

`include "HDL_defines.v"

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
    parameter ADC_CLK_DIV_WIDTH = `__ADC_CLK_DIV_WIDTH,
    parameter MOVING_AVERAGE_ACUM_WIDTH = `__MOVING_AVERAGE_ACUM_WIDTH,

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
    parameter ADDR_DAC_CHA = `__ADDR_DAC_I2C,   // < DELETE PARAM
    parameter ADDR_DAC_CHB = `__ADDR_DAC_I2C,   // < DELETE PARAM
    parameter ADDR_PRETRIGGER = `__ADDR_PRETRIGGER,
    parameter ADDR_NUM_SAMPLES = `__ADDR_NUM_SAMPLES,
    parameter ADDR_TRIGGER_VALUE = `__ADDR_TRIGGER_VALUE,
    parameter ADDR_TRIGGER_SETTINGS = `__ADDR_TRIGGER_SETTINGS,

    // registers default values
    parameter DEFAULT_REQUESTS = `__DEFAULT_REQUESTS,
    parameter DEFAULT_ADC_CLK_DIV_CHA = `__DEFAULT_ADC_CLK_DIV_CHA,
    parameter DEFAULT_ADC_CLK_DIV_CHB = `__DEFAULT_ADC_CLK_DIV_CHB,
    parameter DEFAULT_N_MOVING_AVERAGE_CHA = `__DEFAULT_N_MOVING_AVERAGE_CHA,
    parameter DEFAULT_N_MOVING_AVERAGE_CHB = `__DEFAULT_N_MOVING_AVERAGE_CHB,
    parameter DEFAULT_SETTINGS_CHA = `__DEFAULT_SETTINGS_CHA,
    parameter DEFAULT_SETTINGS_CHB = `__DEFAULT_SETTINGS_CHB,
    parameter DEFAULT_DAC_CHA = `__DEFAULT_DAC_I2C, // < DELETE PARAM
    parameter DEFAULT_DAC_CHB = `__DEFAULT_DAC_I2C, // < DELETE PARAM
    parameter DEFAULT_PRETRIGGER = `__DEFAULT_PRETRIGGER,
    parameter DEFAULT_NUM_SAMPLES = `__DEFAULT_NUM_SAMPLES,
    parameter DEFAULT_TRIGGER_VALUE = `__DEFAULT_TRIGGER_VALUE,
    parameter DEFAULT_TRIGGER_SETTINGS = `__DEFAULT_TRIGGER_SETTINGS
        // trigger_settings: source_sel(00,01,10,11), edge(pos/neg)
    //parameter DEFAULT_ADC_DF_DV_REG = (`__DEFAULT_ADC_CLK_DIV_H << 16) | (`__DEFAULT_ADC_CLK_DIV_L),
  )(
    // Basic
    input   wire clk_i,
    input   wire rst_i,

    // Channel 1 - ADC
    input   wire [BITS_ADC-1:0] chA_adc_in,
    output  wire                chA_adc_oe,
    output  wire                chA_adc_clk_o,
    // Channel 1 - Analog
    output  wire [2:0]          chA_gain_sel,
    output  wire [2:0]          chA_att_sel,
    output  wire                chA_dc_coupling_sel,
    output  wire                chA_on_sel,

    // Channel 2 - ADC
    input   wire [BITS_ADC-1:0] chB_adc_in,
    output  wire                chB_adc_oe,
    output  wire                chB_adc_clk_o,
    // Channel 2 - Analog
    output  wire [2:0]          chB_gain_sel,
    output  wire [2:0]          chB_att_sel,
    output  wire                chB_dc_coupling_sel,
    output  wire                chB_on_sel,

    // Ext
    input wire                  ext_trigger,

    // FT245 interface
    inout   wire [FT245_DATA_WIDTH-1:0] in_out_245,
    input   wire                rxf_245,
    output  wire                rx_245,
    input   wire                txe_245,
    output  wire                wr_245,
    output  wire                siwu,

    inout   wire                sda_io,
    output  wire                scl,

    output  wire                clk_o,
    output  reg [7:0]           leds

);

    // PLL output clock
    wire clk_100M;
    assign clk_o = clk_100M;

    // Registers bus
    wire [REG_ADDR_WIDTH-1:0] reg_addr;
    wire [REG_DATA_WIDTH-1:0] reg_data;
    wire reg_rdy;

    // FT245
    wire [7:0] in_245;
    wire [7:0] out_245;
    wire tx_oe_245;

    wire [RX_DATA_WIDTH-1:0] si_ft245_rx_data;
    wire                si_ft245_rx_rdy;
    wire                si_ft245_rx_ack;

    wire [TX_DATA_WIDTH-1:0] si_ft245_tx_data;
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

    wire global_rst;
    wire pll_lock;
    reg pll_lock_i = 0;
    reg pll_reset = 0;

    always @(posedge clk_100M) begin
        // this delay is probably not necessary...
        pll_lock_i <= pll_lock;
        pll_reset <= ~pll_lock_i;
    end

    wire rst_seq;
    wire rst_comm;
    assign rst_comm = pll_reset | rqst_reset | rst_i;
    assign global_rst = pll_reset | rqst_reset | rst_i | rst_seq;

    // PLL instantiation
    // Sources of info
    // https://github.com/cliffordwolf/yosys/issues/103
    // http://www.latticesemi.com/~/media/LatticeSemi/Documents/TechnicalBriefs/SBTICETechnologyLibrary201504.pdf#page93
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
        .REFERENCECLK(clk_i),
        .PLLOUTCORE(clk_100M),
        .LOCK(pll_lock)
    );

    // Registers Rx Block
    registers_rx_block  #(
        .RX_DATA_WIDTH(RX_DATA_WIDTH),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .REG_DATA_WIDTH(REG_DATA_WIDTH),
        .ADDR_REQUESTS(ADDR_REQUESTS),
        .DEFAULT_REQUESTS(DEFAULT_REQUESTS)
    ) rx_block_u (
        .clk(clk_100M),
        .rst(rst_comm), //global_rst
        .rx_data(si_ft245_rx_data),
        .rx_rdy(si_ft245_rx_rdy),
        .rx_ack(si_ft245_rx_ack),
        .register_addr(reg_addr),
        .register_data(reg_data),
        .register_rdy(reg_rdy),
        .start_o(rqst_start),
        .stop_o(rqst_stop),
        .reset_o(rqst_reset),
        .rqst_ch1(rqst_chA_data),
        .rqst_ch2(rqst_chB_data),
        .rqst_trigger_status_o(rqst_trigger_status),
        .rst_seq(rst_seq)
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
        .rst(global_rst),
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
        .rst(global_rst),
        // SI - Output (FT245)
        .tx_data(si_ft245_tx_data),
        .tx_rdy(si_ft245_tx_rdy),
        .tx_ack(si_ft245_tx_ack),
        // SI - Channel 1
        .ch1_data(tx_chA_data),
        .ch1_rdy(tx_chA_rdy),
        .ch1_eof(tx_chA_eof),
        .ch1_ack(tx_chA_ack),
        // SI - Channel 2
        .ch2_data(tx_chB_data),
        .ch2_rdy(tx_chB_rdy),
        .ch2_eof(tx_chB_eof),
        .ch2_ack(tx_chB_ack),
        // SI - Trigger status
        .trig_data(tx_trigger_status_data),
        .trig_rdy(tx_trigger_status_rdy),
        .trig_eof(tx_trigger_status_eof),
        .trig_ack(tx_trigger_status_ack)
    );


    ft245_interface #(
        .CLOCK_PERIOD_NS(`CLOCK_PERIOD_NS)
    ) ft245_u (
        .clk(clk_100M),
        .rst(rst_comm), //global_rst

        .rx_data_245(in_245),
        .rxf_245(rxf_245),
        .rx_245(rx_245),

        .tx_data_245(out_245),
        .txe_245(txe_245),
        .wr_245(wr_245),
        .tx_oe_245(tx_oe_245),

        .rx_data_si(si_ft245_rx_data),
        .rx_rdy_si(si_ft245_rx_rdy),
        .rx_ack_si(si_ft245_rx_ack),

        .tx_data_si(si_ft245_tx_data),
        .tx_rdy_si(si_ft245_tx_rdy),
        .tx_ack_si(si_ft245_tx_ack)
    );

    genvar h;
    generate
        for (h=0 ; h<8 ; h=h+1) begin
            SB_IO #(
                .PIN_TYPE(6'b101001),
                .PULLUP(1'b0)
            ) IO_PIN_INST (
                .PACKAGE_PIN (in_out_245[h]),
                .LATCH_INPUT_VALUE (),
                .CLOCK_ENABLE (),
                .INPUT_CLK (),
                .OUTPUT_CLK (),
                .OUTPUT_ENABLE (tx_oe_245),
                .D_OUT_0 (out_245[h]),
                .D_OUT_1 (),
                .D_IN_0 (in_245[h]),
                .D_IN_1 ()
            );
        end
    endgenerate


    // Channel Block
    channel_block #(
        .BITS_ADC(BITS_ADC),
        .BITS_DAC(BITS_DAC),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .REG_DATA_WIDTH(REG_DATA_WIDTH),
        .TX_DATA_WIDTH(TX_DATA_WIDTH),
        .RAM_DATA_WIDTH(RAM_DATA_WIDTH),
        .RAM_SIZE(RAM_SIZE),
        .ADC_CLK_DIV_WIDTH(ADC_CLK_DIV_WIDTH),
        .MOVING_AVERAGE_ACUM_WIDTH(MOVING_AVERAGE_ACUM_WIDTH),
        .ADDR_CH_SETTINGS(ADDR_SETTINGS_CHA),
        .ADDR_DAC_VALUE(ADDR_DAC_CHA),
        .ADDR_ADC_CLK_DIV_L(ADDR_ADC_CLK_DIV_CHA_L),
        .ADDR_ADC_CLK_DIV_H(ADDR_ADC_CLK_DIV_CHA_H),
        .ADDR_N_MOVING_AVERAGE(ADDR_N_MOVING_AVERAGE_CHA),
        .DEFAULT_CH_SETTINGS(DEFAULT_SETTINGS_CHA),
        .DEFAULT_DAC_VALUE(DEFAULT_DAC_CHA),
        .DEFAULT_ADC_CLK_DIV(DEFAULT_ADC_CLK_DIV_CHA),
        .DEFAULT_N_MOVING_AVERAGE(DEFAULT_N_MOVING_AVERAGE_CHA)
    ) channel_block_A(
        .clk(clk_100M),
        .rst(global_rst),
        // iInterface with ADC pins
        .adc_input(chA_adc_in),
        .adc_oe(chA_adc_oe),
        .adc_clk_o(chA_adc_clk_o),
        // Interface with MUXes
        .Att_Sel(chA_att_sel),
        .Gain_Sel(chA_gain_sel),
        .DC_Coupling(chA_dc_coupling_sel),
        .Channel_On(chA_on_sel),
        // Buffer Controller
        .rqst_data(rqst_chA_data),
        .we(we),
        .num_samples(num_samples),
        // Registers Bus
        .register_addr(reg_addr),
        .register_data(reg_data),
        .register_rdy(reg_rdy),
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
        .ADC_CLK_DIV_WIDTH(ADC_CLK_DIV_WIDTH),
        .MOVING_AVERAGE_ACUM_WIDTH(MOVING_AVERAGE_ACUM_WIDTH),
        .ADDR_CH_SETTINGS(ADDR_SETTINGS_CHB),
        .ADDR_DAC_VALUE(ADDR_DAC_CHB),
        .ADDR_ADC_CLK_DIV_L(ADDR_ADC_CLK_DIV_CHB_L),
        .ADDR_ADC_CLK_DIV_H(ADDR_ADC_CLK_DIV_CHB_H),
        .ADDR_N_MOVING_AVERAGE(ADDR_N_MOVING_AVERAGE_CHB),
        .DEFAULT_CH_SETTINGS(DEFAULT_SETTINGS_CHB),
        .DEFAULT_DAC_VALUE(DEFAULT_DAC_CHB),
        .DEFAULT_ADC_CLK_DIV(DEFAULT_ADC_CLK_DIV_CHB),
        .DEFAULT_N_MOVING_AVERAGE(DEFAULT_N_MOVING_AVERAGE_CHB)
    ) channel_block_B(
        .clk(clk_100M),
        .rst(global_rst),
        // iInterface with ADC pins
        .adc_input(chB_adc_in),
        .adc_oe(chB_adc_oe),
        .adc_clk_o(chB_adc_clk_o),
        // Interface with MUXes
        .Att_Sel(chB_att_sel),
        .Gain_Sel(chB_gain_sel),
        .DC_Coupling(chB_dc_coupling_sel),
        .Channel_On(chB_on_sel),
        // Buffer Controller
        .rqst_data(rqst_chB_data),
        .we(we),
        .num_samples(num_samples),
        // Registers Bus
        .register_addr(reg_addr),
        .register_data(reg_data),
        .register_rdy(reg_rdy),
        // Trigger source
        .adc_data_o(chB_adc_data),
        .adc_rdy_o(chB_adc_rdy),
        // Tx Protocol
        .tx_data(tx_chB_data),
        .tx_rdy(tx_chB_rdy),
        .tx_eof(tx_chB_eof),
        .tx_ack(tx_chB_ack)
    );


    i2c_wrapper #(
        .REGISTER_ADDR_WIDTH(`__REG_ADDR_WIDTH),
        .REGISTER_DATA_WIDTH(`__REG_DATA_WIDTH),
        .DAC_I2C_REGISTER_ADDR(`__ADDR_DAC_I2C),
        .DAC_I2C_REGISTER_DEFAULT(`__DEFAULT_DAC_I2C),
        .I2C_CLOCK_DIVIDER(`__I2C_CLOCK_DIVIDER),
        .I2C_FIFO_LENGTH(`__I2C_FIFO_LENGTH)
    ) i2c_instance (
        .clk(clk_100M),
        .rst(global_rst),
        .register_addr(reg_addr),
        .register_data(reg_data),
        .register_rdy(reg_rdy),
        .scl(scl),
        .sda_io(sda_io)
    );


    always @(posedge clk_100M) begin
        // if(si_ft245_rx_rdy) leds <= si_ft245_rx_data;
        /*if(reg_rdy==1'b1) begin
            leds <= { {(8-REG_ADDR_WIDTH){1'b0}} , {reg_addr} };
        end*/
        /*if(scl==1'b0) begin
            leds[7:6] <= ~leds[7:6];
            leds[5] <= 1'b0;
        end*/
        /*if(register_addr==`__ADDR_DAC_I2C) begin
            if(register_rdy==1'b1) begin
                leds <= 8'hAA;
            end
        end
        */
        if(si_ft245_rx_rdy == 1'b1) begin
            leds <= si_ft245_rx_data;
        end
    end

    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,top_level);
            #1;
        end
    `endif

endmodule // adc_block
