/*

    Instantiated Modules:
        ram_controller
        adc_block
        analog_controller

    Instantiated Registers:
        channel_settings
        decimation_factor (for adc clock)
        N_moving_average
        ...

*/

`timescale 1ns/1ps

module channel_block #(
    parameter BITS_ADC = 8,
    parameter REG_ADDR_WIDTH = 5,
    parameter REG_DATA_WIDTH = 8,
    parameter TX_DATA_WIDTH = 8,
    parameter RAM_DATA_WIDTH = 8,
    parameter RAM_SIZE = (4096*4)

) (
    // Basic synchronous signals
    input   clk,
    input   rst,

    // ADC interface with pins
    input [BITS_ADC-1:0] adc_input,
    output adc_oe;
    output adc_clk_o;

    // Buffer Controller
    input   rqst_data,
    input   we,

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
