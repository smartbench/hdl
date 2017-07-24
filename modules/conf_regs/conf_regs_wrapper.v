

/*

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
    output request_ack,

    // muxes and switches
    output [2:0] CHA_ATT,
    output [2:0] CHA_GAIN,
    output CHA_DC_COUPLING,
    output [2:0]CHB_ATT,
    output [2:0]CHB_GAIN,
    output CHB_DC_COUPLING,

    // DAC Simple Interface
    output [BITS_DAC-1:0] ch1_dac_value,     // DAC value
    output [BITS_DAC-1:0] ch2_dac_value,     // DAC value
    output reg dac_changed,         // new value must be sent to DAC
    //output SDA,
    //output SCL,

    output [BITS_ADC-1:0] trigger_value,
    output [15:0] num_samples,
    output [15:0] pre_trigger,
    output [1:0] trigger_source,
    output trigger_edge,
    output trigger_conf,

    output reg start_o,
    output reg reset_o,

);

    // Assign register to 2D matrix
    wire [DATA_WIDTH-1:0] array_registers [0:NUM_REGS-1];
    genvar h;
    generate
        for(h = 0 ; h < NUM_REGS ; h = h + 1)
            assign array_registers [h] [DATA_WIDTH-1:0] = registers [ (h + 1) * DATA_WIDTH - 1  : h * DATA_WIDTH ] ;
    endgenerate

    localparam  ADDR_RQST           = 0;
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

    // Addr 0x0000 (REQUESTS)
    assign rqst_reset       = array_registers[ADDR_RQST][1];
    assign rqst_start       = array_registers[ADDR_RQST][0];

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


    always @(posedge clk) begin
        request_ack <= 1'b0;
        start_o <= 1'b0;
        reset_o <= 1'b0;
        if (reset == 1'b1) begin                                            // RESET
            // Default values
        end else begin
            if (start_o != rqst_start) begin
                start_o <= 1'b1;
                request_ack <= 1'b1;
            end
            if (reset_o != rqst_reset) begin
                reset_o <= 1'b1;
                request_ack <= 1'b1;
            end
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
