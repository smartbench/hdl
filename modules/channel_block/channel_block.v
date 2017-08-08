/*

    Instantiated Modules:
        ram_controller
        adc_block
        dac_controller

    Instantiated Registers:
        channel_settings
        ...

*/

`timescale 1ns/1ps

module channel_block #(
    parameter BITS_ADC = 8,
    parameter BITS_DAC = 10,
    parameter REG_ADDR_WIDTH = 5,
    parameter REG_DATA_WIDTH = 8,
    parameter TX_DATA_WIDTH = 8,
    parameter RAM_DATA_WIDTH = 8,
    parameter RAM_SIZE = (4096*4),

    parameter ADDR_CH_SETTINGS,
    parameter ADDR_DAC_VALUE_H,
    parameter ADDR_DAC_VALUE_L,
    /* ... Faltan ... */
    parameter DEFAULT_CH_SETTINGS,
    parameter DEFAULT_DAC_VALUE_H,
    parameter DEFAULT_DAC_VALUE_L,
    /* ... Faltan ... */
) (
    // Basic synchronous signals
    input   clk,
    input   rst,

    // iInterface with ADC pins
    input [BITS_ADC-1:0] adc_input,
    output adc_oe;
    output adc_clk_o;

    // Interface with MUXes
    output  [2:0] Att_Sel,
    output  [2:0] Gain_Sel,
    output  DC_Coupling,
    // ChannelOn

    // Buffer Controller
    input   rqst_data,
    input   we,
    input   [15:0] num_samples,

    // Registers Bus
    input   [REG_ADDR_WIDTH-1:0] reg_addr,
    input   [REG_DATA_WIDTH-1:0] reg_data,
    input   reg_rdy,

    // Trigger source
    output  [BITS_ADC-1:0] adc_data_o,
    output  adc_rdy_o,

    // Tx Protocol
    output  [TX_DATA_WIDTH-1:0] tx_data,
    output  tx_rdy,
    output  tx_eof,
    input   tx_ack,

);

    // ADC <--> RAM Controller
    // ADC ---> Trigger Source Selector
    wire    [BITS_ADC-1:0] si_adc_data,
    wire    si_adc_rdy,
    wire    si_adc_ack,

    assign  adc_data_o = si_adc_data;
    assign  adc_rdy_o = si_adc_rdy;

    fully_associative_register #(
        .ADDR_WIDTH     (REG_ADDR_WIDTH),
        .DATA_WIDTH     (REG_DATA_WIDTH),
        .MY_ADDR        (ADDR_CH_SETTINGS),
        .MY_RESET_VALUE (DEFAULT_CH_SETTINGS)
    ) reg_Channel_settings (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),
        // .data        ( { Att_Sel , Gain_Sel , DC_Coupling , Channel_On } )
        .data[7:5]      (Att_Sel),
        .data[4:2]      (Gain_Sel),
        .data[1]        (DC_Coupling),
        .data[0]        (Channel_On)
    );

    fully_associative_register #(
        .ADDR_WIDTH     (REG_ADDR_WIDTH),
        .DATA_WIDTH     (REG_DATA_WIDTH),
        .MY_ADDR        (ADDR_DAC_VALUE),
        .MY_RESET_VALUE (DEFAULT_DAC_VALUE)
    ) reg_DAC_Value_H (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),

        // .data        ( { CHA_ATT , CHA_GAIN , CHA_DC_COUPLING , CHA_ON } )
        .data           (dac_val[15:8])
    );

    // Source CH1
    ram_controller #(
        .RAM_DATA_WIDTH(RAM_DATA_WIDTH),
        .RAM_SIZE(RAM_SIZE)
    ) ram_controller_ch1_u(
        .clk(clk),
        .rst(rst),
        // Input (Buffer Controller)
        .wr_en(we),
        .rqst_buff(rqst_data),
        .n_samples(num_samples),
        // Internal (ADC)
        .din(si_adc_data),
        .si_rdy_adc(si_adc_rdy),
        .si_ack_adc(si_adc_ack),
        // Output (Tx Protocol)
        .data_out(tx_data),
        .data_rdy(tx_rdy),
        .data_eof(tx_eof),
        .data_ack(tx_ack)
    );

    // ADC
    adc_top #(
        .ADC_DATA_WIDTH(BITS_ADC),
        .ADC_DF_WIDTH(32),
        .MA_BITS_ACUM(12),
        .SI_DATA_WIDTH(32)
    ) adc_block(
        .clk_i(clk),
        .reset(rst),
        // ADC interface (to the ADC outside of the FPGA)
        .ADC_data(adc_input),
        .ADC_oe(adc_oe),
        .clk_o(adc_clk_o),
        // Internal (RAM Controller) and Output (Trigger Source Selector)
        .ADC_SI_data(si_adc_data),
        .ADC_SI_rdy(si_adc_rdy),
        .ADC_SI_ack(si_adc_ack),
        // Input (Registers Simple Interface Bus)
        .REG_SI_data(reg_data),
        .REG_SI_addr(reg_addr),
        .REG_SI_rdy(reg_rdy),
    );

    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("waveform_channel.vcd");
      $dumpvars (0,channel_block);
      #1;
    end
    `endif

endmodule
