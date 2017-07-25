

/*
    Configuration Registers Wrapper Module
    
    This module connencts the bit array of the configuration registers with Named easily identifiable nets.
    Also has the logic to handle the Event Register and send the corresponding signals to other modules.

*/

`timescale 1ns/1ps

module conf_regs_wrapper  #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 16,
    parameter NUM_REGS = 20,
    parameter BITS_DAC = 8,
    parameter BITS_ADC = 8,
) (
                                // Description                  Type            Width
    // Basic
    input clk,                  // fpga clock                   input           1
    input rst,                  // synch reset                  input           1

    // registers
    input [DATA_WIDTH * NUM_REGS-1:0] registers,
                                // registers data
    input reg [DATA_WIDTH-1:0] request_reg_data,
                                // request_reg data
    output reg request_reg_ack = 1'b0,

    // Analog Muxes and Switches
    output [2:0] CHA_ATT,
    output [2:0] CHA_GAIN,
    output CHA_DC_COUPLING,
    output CHA_ON,
    output [2:0]CHB_ATT,
    output [2:0]CHB_GAIN,
    output CHB_DC_COUPLING,
    output CHB_ON,

    // ADCs
    input [BITS_ADC-1:0] ch1_in,
    input [BITS_ADC-1:0] ch2_in,
    input ext_in,

    // DACs
    output [BITS_DAC-1:0] ch1_dac_value,     // DAC value
    output [BITS_DAC-1:0] ch2_dac_value,     // DAC value

    // Buffer Controller
    output [BITS_ADC-1:0] trigger_value,
    output [15:0] num_samples,
    output [15:0] pre_trigger,
    output bc_input_rdy,
    output trigger_edge,
    output trigger_conf,
    output input_sample,
    input buffer_controller_we,

    // ADCs
    input adc_ch1_rdy,
    input adc_ch2_rdy,

    // RAM Controller
    output ram_controller_ch1_we,
    output ram_controller_ch2_we,

    // ...
    output reg start_o,
    output reg reset_o,

);

    // Not necessary outside this module
    wire [1:0] trigger_source;

    // The trigger's source is muxed to 'tmp_input_sample'.
    // Then, the edge detector input is the source directly, or negated bit by bit,
    //  depending on the edge_type configuration (p_edge or n_edge).
    wire [BITS_ADC-1:0] tmp_input_sample;

    // Reads registers as a 2D matrix to perform a less confusing assignation.
    wire [DATA_WIDTH-1:0] array_registers [0:NUM_REGS-1];
    genvar h;
    generate
        for(h = 0 ; h < NUM_REGS ; h = h + 1)
            assign array_registers [h] [DATA_WIDTH-1:0] = registers [ (h + 1) * DATA_WIDTH - 1  : h * DATA_WIDTH ] ;
    endgenerate

    // Registers addresses
//    localparam  ADDR_RQST           = 0;
    localparam  ADDR_CONF_CH1       = 1;
    localparam  ADDR_CONF_CH2       = 2;
    localparam  ADDR_DAC_CH1        = 3;
    localparam  ADDR_DAC_CH2        = 4;
    localparam  ADDR_TRIGGER_CONF   = 5;
    localparam  ADDR_TRIGGER_VALUE  = 6;
    localparam  ADDR_NUM_SAMPLES    = 7;
    localparam  ADDR_PRE_TRIGGER    = 8;
    localparam  ADDR_DECIMATION_L   = 9;
    localparam  ADDR_DECIMATION_H   = 10;

    // Trigger source
    localparam  src_XXX = 2'b00,
                src_CH1 = 2'b01,
                src_CH2 = 2'b10,
                src_EXT = 2'b11;

    // Trigger edge
    localparam  p_edge=1'b0,
                n_edge=1'b1;

    // A Zero of size [BITS_ADC-1] bits.
    localparam [BITS_ADC-2:0] ZERO = 0; // ... ?

    // Addr 0x0000 (REQUESTS)
    assign rqst_reset       = request_reg_data[1];
    assign rqst_start       = request_reg_data[0];

    // Addr 0x0001
    assign CHA_ATT [2:0]    = array_registers[ADDR_ANALOG_CH1][7:5];
    assign CHA_GAIN [2:0]   = array_registers[ADDR_ANALOG_CH1][4:2];
    assign CHA_DC_COUPLING  = array_registers[ADDR_ANALOG_CH1][1];
    assign CHA_ON           = array_registers[ADDR_ANALOG_CH1][0];

    // Addr 0x0002
    assign CHB_ATT [2:0]    = array_registers[ADDR_ANALOG_CH2][7:5];
    assign CHB_GAIN [2:0]   = array_registers[ADDR_ANALOG_CH2][4:2];
    assign CHB_DC_COUPLING  = array_registers[ADDR_ANALOG_CH2][1];
    assign CHB_ON           = array_registers[ADDR_ANALOG_CH2][0];

    // Addr 0x0003
    assign ch1_dac_value [BITS_DAC-1:0] = array_registers[ADDR_DAC_CH1][BITS_DAC-1:0];

    // Addr 0x0004
    assign ch2_dac_value [BITS_DAC-1:0] = array_registers[ADDR_DAC_CH2][BITS_DAC-1:0];

    // Addr 0x0005
    assign trigger_conf         = array_registers[ADDR_TRIGGER_CONF][3];
    assign trigger_edge         = array_registers[ADDR_TRIGGER_CONF][2];
    assign trigger_source [1:0] = array_registers[ADDR_TRIGGER_CONF][1:0];

    // Addr 0x0006
    assign trigger_value [BITS_ADC-1:0]  = array_registers[ADDR_TRIGGER_VALUE][BITS_ADC-1:0];

    // Addr 0x0007
    assign num_samples [15:0]   = array_registers[ADDR_NUM_SAMPLES][15:0];

    // Addr 0x0008
    assign pre_trigger [15:0]   = array_registers[ADDR_PRE_TRIGGER][15:0];

    // Addr 0x0009 and 0x000A
    assign decimation_factor[31:16] = array_registers[ADDR_DECIMATION_H][15:0];
    assign decimation_factor[15:00] = array_registers[ADDR_DECIMATION_L][15:0];

    // buffer controller's 'input_rdy' bit, depends on the trigger's source
    assign bc_input_rdy =   (trigger_source == src_CH1) ? adc_ch1_rdy :
                            (trigger_source == src_CH2) ? adc_ch2_rdy :
                            (trigger_source == src_EXT) ? (adc_ch1_rdy | adc_ch2_rdy) :
                                                          1'b0;

    // Detector Trigger Value = Trigger Value, unless Trigger Source == EXT.
    //  When EXT source, Trigger Value = b01000...0, and input_sample = {ext_in , 00...0}.
    //  This way the ext_in controlls the MSB of input_sample, so when it turns from 0 to 1,
    //  (or 1 to 0) it'll cross the Trigger Value
    assign trigger_value[BITS_ADC-1:0] = (trigger_source == src_EXT) ? (1 << (BITS_ADC-2)) : trigger_value[BITS_ADC-1:0];

    // MUX for trigger source selection
    assign tmp_input_sample[BITS_ADC-1:0] = (trigger_source == src_CH1) ? ch1_in :
                                            (trigger_source == src_CH2) ? ch2_in :
                                            (trigger_source == src_EXT) ? {ext_in, ZERO} :
                                                                          0;

    // Edge type: negate bits to change to negative edge type.
    assign input_sample = (edge_type == p_edge) ? tmp_input_sample : ~tmp_input_sample;

    // The write of the RAM is controlled with the 'rdy' bit of the corresponding channel,
    //  and the 'write_enable' bit of the buffer controller.
    assign ram_controller_ch1_we = adc_ch1_rdy & buffer_controller_we;
    assign ram_controller_ch2_we = adc_ch1_rdy & buffer_controller_we;

    // Control of the requests received via Request_Register
    always @(posedge clk) begin
        request_reg_ack <= 1'b0;
        start_o <= 1'b0;
        reset_o <= 1'b0;
        if (start_o != rqst_start) begin
            start_o <= 1'b1;
            request_reg_ack <= 1'b1;
        end
        if (reset_o != rqst_reset) begin
            reset_o <= 1'b1;
            request_reg_ack <= 1'b1;
        end
    end


    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,conf_regs_wrapper);
            #1;
        end
    `endif

endmodule
