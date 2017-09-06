/*

    Instantiated Modules:
        ram_controller
        adc_block


    Instantiated Registers:
        channel_settings
        ...

*/

`include "HDL_defines.v"

`timescale 1ns/1ps

module channel_block #(
    parameter BITS_ADC = 8,
    parameter BITS_DAC = 10,
    parameter REG_ADDR_WIDTH = 8,
    parameter REG_DATA_WIDTH = 16,
    parameter TX_DATA_WIDTH = 8,
    parameter RAM_DATA_WIDTH = 8,
    parameter RAM_SIZE = 4096,

    parameter ADC_CLK_DIV_WIDTH = 32,
    parameter MOVING_AVERAGE_ACUM_WIDTH = 12,

    parameter ADDR_CH_SETTINGS = 0,
    parameter ADDR_DAC_VALUE = 1,
    parameter ADDR_ADC_CLK_DIV_L = 2,
    parameter ADDR_ADC_CLK_DIV_H = 3,
    parameter ADDR_N_MOVING_AVERAGE = 4,

    parameter DEFAULT_CH_SETTINGS = 16'b0000000011100001,
    parameter DEFAULT_DAC_VALUE = (1 << (BITS_DAC-1)),
    parameter DEFAULT_ADC_CLK_DIV = 1,
    parameter DEFAULT_N_MOVING_AVERAGE = 1
) (
    // Basic synchronous signals
    input   clk,
    input   rst,

    // iInterface with ADC pins
    input [BITS_ADC-1:0] adc_input,
    output adc_oe,
    output adc_clk_o,

    // Interface with MUXes
    output  [2:0] Att_Sel,
    output  [2:0] Gain_Sel,
    output  DC_Coupling,
    output  Channel_On,

    // Buffer Controller
    input   rqst_data,
    input   we,
    input   [15:0] num_samples,

    // Registers Bus
    input   [REG_ADDR_WIDTH-1:0] register_addr,
    input   [REG_DATA_WIDTH-1:0] register_data,
    input   register_rdy,

    // Trigger source
    output  [BITS_ADC-1:0] adc_data_o,
    output  adc_rdy_o,

    // Tx Protocol
    output  [TX_DATA_WIDTH-1:0] tx_data,
    output  tx_rdy,
    output  tx_eof,
    input   tx_ack

);

    // ADC <--> RAM Controller
    // ADC ---> Trigger Source Selector
    wire    [BITS_ADC-1:0] si_adc_data;
    wire    si_adc_rdy;
    wire    si_adc_ack; // not used!

    wire [REG_DATA_WIDTH-1:0] dac_val;

    assign  adc_data_o = si_adc_data;
    assign  adc_rdy_o = si_adc_rdy;

    // Register Channel Configuration (gain, att, coupling)

    wire [REG_DATA_WIDTH-1:0] reg_Channel_settings_data;

    fully_associative_register #(
        .REG_ADDR_WIDTH (REG_ADDR_WIDTH),
        .REG_DATA_WIDTH (REG_DATA_WIDTH),
        .MY_ADDR        (ADDR_CH_SETTINGS),
        .MY_RESET_VALUE (DEFAULT_CH_SETTINGS)
    ) reg_Channel_settings (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),
        .data           (reg_Channel_settings_data)
        // .data        ( { Att_Sel , Gain_Sel , DC_Coupling , Channel_On } )
    );
    assign Att_Sel = reg_Channel_settings_data[7:5] ;
    assign Gain_Sel = reg_Channel_settings_data[4:2];
    assign DC_Coupling = reg_Channel_settings_data[1];
    assign Channel_On = reg_Channel_settings_data[0] ;

    // Register DAC value


    fully_associative_register #(
        .REG_ADDR_WIDTH     (REG_ADDR_WIDTH),
        .REG_DATA_WIDTH     (REG_DATA_WIDTH),
        .MY_ADDR            (ADDR_DAC_VALUE),
        .MY_RESET_VALUE     (DEFAULT_DAC_VALUE)
    ) reg_DAC_Value (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),
        .data           (dac_val)
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
        .si_ack_adc(si_adc_ack), //not used!
        // Output (Tx Protocol)
        .data_out(tx_data),
        .data_rdy(tx_rdy),
        .data_eof(tx_eof),
        .data_ack(tx_ack)
    );

    // ADC
    adc_block #(
        .BITS_ADC(BITS_ADC),
        .ADC_CLK_DIV_WIDTH(ADC_CLK_DIV_WIDTH),
        .MOVING_AVERAGE_ACUM_WIDTH(MOVING_AVERAGE_ACUM_WIDTH),
        .REG_DATA_WIDTH(REG_DATA_WIDTH),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .ADDR_ADC_CLK_DIV_L(ADDR_ADC_CLK_DIV_L),
        .ADDR_ADC_CLK_DIV_H(ADDR_ADC_CLK_DIV_H),
        .ADDR_N_MOVING_AVERAGE(ADDR_N_MOVING_AVERAGE),
        .DEFAULT_ADC_CLK_DIV(DEFAULT_ADC_CLK_DIV),
        .DEFAULT_N_MOVING_AVERAGE(DEFAULT_N_MOVING_AVERAGE)
    ) adc_block_u (
        .clk_i(clk),
        .rst(rst),
        // ADC interface (to the ADC outside of the FPGA)
        .adc_data_i(adc_input),
        .adc_oe(adc_oe),
        .clk_o(adc_clk_o),
        // Internal (RAM Controller) and Output (Trigger Source Selector)
        .si_data_o(si_adc_data),
        .si_rdy_o(si_adc_rdy),
        // Input (Registers Simple Interface Bus)
        .reg_si_data(register_data),
        .reg_si_addr(register_addr),
        .reg_si_rdy(register_rdy)
    );

    `ifdef COCOTB_SIM
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,channel_block);
            #1;
        end
    `endif

endmodule
