

/*
    Trigger Block

    Instanciates:
    > trigger_input_selector
    > Buffer_Controller
    > registers
        - PRETRIGGER_H,
        - PRETRIGGER_L,
        - NUM_SAMPLES_H,
        - NUM_SAMPLES_L,
        - TRIGGER_VALUE,
        - TRIGGER_SETTINGS,

*/

`timescale 1ns/1ps

module trigger_block  #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 8,
    parameter BITS_DAC = 8,
    parameter BITS_ADC = 8,
    // addresses
    parameter ADDR_PRETRIGGER_H,
    parameter ADDR_PRETRIGGER_L,
    parameter ADDR_NUM_SAMPLES_H,
    parameter ADDR_NUM_SAMPLES_L,
    parameter ADDR_TRIGGER_VALUE,
    parameter ADDR_TRIGGER_SETTINGS,
    // default values
    parameter DEFAULT_PRETRIGGER_H,
    parameter DEFAULT_PRETRIGGER_L,
    parameter DEFAULT_NUM_SAMPLES_H,
    parameter DEFAULT_NUM_SAMPLES_L,
    parameter DEFAULT_TRIGGER_VALUE,
    parameter DEFAULT_TRIGGER_SETTINGS // trigger_settings: mode(single/normal), edge(pos/neg), source_sel(00,01,10,11)
) (
                                // Description                  Type            Width
    input clk,
    input rst,

    // Request handler
    input start,
    input stop,     // must be ORed with rqst_ch1 and rqst_ch2!!
    input rqst_trigger_status,
    // NO //input rqst_ch1, rqst_

    // Tx Protocol
    output [7:0] trigger_status_data,
    output trigger_status_rdy,
    output trigger_status_eof,
    input trigger_status_ack,

    // ADCs
    input [BITS_ADC-1:0] ch1_in,
    input [BITS_ADC-1:0] ch2_in,
    input ext_in,
    input adc_ch1_rdy,
    input adc_ch2_rdy,

    // Ram Controller
    output we,

    // Registers bus
    input [ADDR_WIDTH-1:0] register_addr,
    input [DATA_WIDTH-1:0] register_data,
    input register_rdy,
);

    // Buffer Controller
    wire trigger_source_data,
    wire trigger_source_rdy;
    wire [BITS_ADC-1:0] trigger_value_o;

    // Registers
    wire [15:0] pretrigger;
    wire [15:0] num_samples;
    wire [BITS_ADC-1:0] trigger_value_i;

    wire [1:0] trigger_source_sel,
    wire trigger_conf,
    wire trigger_edge,


    // Pretrigger Registers
    fully_associative_register #(
        .ADDR_WIDTH     (REG_ADDR_WIDTH),
        .DATA_WIDTH     (REG_DATA_WIDTH),
        .MY_ADDR        (ADDR_PRETRIGGER_H),
        .MY_RESET_VALUE (DEFAULT_PRETRIGGER_H)
    ) reg_pretrigger_H (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),
        .data           (pretrigger[15:8])
    );
    fully_associative_register #(
        .ADDR_WIDTH     (REG_ADDR_WIDTH),
        .DATA_WIDTH     (REG_DATA_WIDTH),
        .MY_ADDR        (ADDR_PRETRIGGER_L),
        .MY_RESET_VALUE (DEFAULT_PRETRIGGER_L)
    ) reg_pretrigger_L (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),
        .data           (pretrigger[7:0])
    );

    // Number of Samples Registers
    fully_associative_register #(
        .ADDR_WIDTH     (REG_ADDR_WIDTH),
        .DATA_WIDTH     (REG_DATA_WIDTH),
        .MY_ADDR        (ADDR_NUM_SAMPLES_H),
        .MY_RESET_VALUE (DEFAULT_NUM_SAMPLES_H)
    ) reg_num_samples_H (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),
        .data           (num_samples[15:8])
    );
    fully_associative_register #(
        .ADDR_WIDTH     (REG_ADDR_WIDTH),
        .DATA_WIDTH     (REG_DATA_WIDTH),
        .MY_ADDR        (ADDR_NUM_SAMPLES_L),
        .MY_RESET_VALUE (DEFAULT_NUM_SAMPLES_L)
    ) reg_num_samples_L (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),
        .data           (num_samples[7:0])
    );

    // Trigger Value Register
    fully_associative_register #(
        .ADDR_WIDTH     (REG_ADDR_WIDTH),
        .DATA_WIDTH     (REG_DATA_WIDTH),
        .MY_ADDR        (ADDR_TRIGGER_VALUE),
        .MY_RESET_VALUE (DEFAULT_TRIGGER_VALUE)
    ) reg_trigger_value (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),
        .data           (trigger_value_i[BITS_ADC-1:0])
    );

    // Trigger Settings Register
    fully_associative_register #(
        .ADDR_WIDTH     (REG_ADDR_WIDTH),
        .DATA_WIDTH     (REG_DATA_WIDTH),
        .MY_ADDR        (ADDR_TRIGGER_SETTINGS),
        .MY_RESET_VALUE (DEFAULT_TRIGGER_SETTINGS)
    ) reg_trigger_settings (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),
        .data[3:2]      (trigger_source_sel)
        .data[1]        (trigger_conf)
        .data[0]        (trigger_edge)
    );
    /*
    fully_associative_register #(
        .ADDR_WIDTH     (REG_ADDR_WIDTH),
        .DATA_WIDTH     (REG_DATA_WIDTH),
        .MY_ADDR        (),
        .MY_RESET_VALUE ()
    ) reg_Channel_settings (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),
        .data           ()
    );
    */

    buffer_controller  #(
        .BITS_ADC   (BITS_ADC)
    ) buffer_controller_u (
        .clk(clk),
        .rst(rst),
        // Request Handler
        .start          (start)
        .stop           (stop)
        .rqst_trigger_status    (rqst_trigger_status),
        // From Trigger Input Selector
        .input_sample   (trigger_source_data),
        .input_rdy      (trigger_source_rdy),
        // Registers
        .num_samples    (num_samples),
        .pre_trigger    (pretrigger),
        .trigger_value  (trigger_value),
        // Ram controller
        .write_enable   (we),
        // Tx Protocol
        .trigger_status_data    (trigger_status_data),
        .trigger_status_rdy     (trigger_status_rdy),
        .trigger_status_eof     (trigger_status_eof),
        .trigger_status_ack     (trigger_status_ack)
    );

    trigger_input_selector #(
        .ADDR_WIDTH = 8,
        .DATA_WIDTH = 8,
        .BITS_ADC = 8,
        .BITS_DAC = 10
    )  (
        .ch1_in         (ch1_in),
        .ch2_in         (ch2_in),
        ext_in          (ext_in),
        adc_ch1_rdy     (adc_ch1_rdy),
        adc_ch2_rdy     (adc_ch2_rdy),

        // Data from Registers
        .trigger_value_in       (trigger_value_i),
        .trigger_source_sel     (trigger_source_sel),
        .trigger_edge_type      (trigger_edge),

        // Buffer Controller
        .trigger_value_out      (trigger_value_o),
        .trigger_source_out     (trigger_source_data),
        .buffer_cont_input_rdy  (trigger_source_rdy)
    );

    `ifdef COCOTB_SIM               // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,trigger_block);
            #1;
        end
    `endif

endmodule
