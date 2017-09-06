

/*
    Trigger Input Selector

    This module connencts the corresponding trigger's source and trigger value to the buffer controller according to the
    configuration stored in the trigger configuration registers.
    Only combinational logic here!

    The trigger configuration inputs are:

    - trigger_edge_type: selection of positive edge detection or negative edge detection.
        when positive edge is selected, the input of the buffer_controller is the trigger's source,
        and when negative edge is selected, the input of the buffer_controller is the trigger's
        source bitwise negated.
        0: positive edge detection
        1: negative edge detection.

    - trigger_source_sel[2]: selection of the trigger's source.
        00: UNDEFINED
        01: CH1
        10: CH2
        11: EXT

    - trigger_value[BITS_ADC]: Trigger Value.
        When the source crosses this value (pos / neg edge), the scope triggers.

    Special case: to avoid adding logic, when EXT is selected, since it's a single bit,
    the trigger's source is this bit sign-extended, and the trigger value is set to
    100...0. This way a change from 0 to 1 in EXT will trigger the scope. (If negative edge is
    selected, the trigger source is inverted and the scope will trigger when it changes from 1 to 0)

    Also has the logic to handle the Event Register and send the corresponding signals to other modules.

*/

`timescale 1ns/1ps

module trigger_input_selector  #(
    parameter REG_ADDR_WIDTH = 8,
    parameter REG_DATA_WIDTH = 16,
    parameter BITS_DAC = 10,
    parameter BITS_ADC = 8
) (
                                // Description                  Type            Width
    // No clock here...

    // ADCs
    input [BITS_ADC-1:0] ch1_in,
    input [BITS_ADC-1:0] ch2_in,
    input ext_in,
    input adc_ch1_rdy,
    input adc_ch2_rdy,

    // Data from Registers
    input [BITS_ADC-1:0] trigger_value_in,
    input [1:0] trigger_source_sel,
    input trigger_edge_type,

    // Buffer Controller
    output [BITS_ADC-1:0] trigger_value_out,
    output [BITS_ADC-1:0] trigger_source_out,
    output trigger_source_rdy

);

    // The trigger's source is muxed to 'tmp_input_sample'.
    // Then, the edge detector input is the source directly, or negated bit by bit,
    //  depending on the edge_type configuration (p_edge or n_edge).
    wire [BITS_ADC-1:0] tmp_trigger_source;

    // Trigger source
    localparam  src_XXX = 2'b00,
                src_CH1 = 2'b01,
                src_CH2 = 2'b10,
                src_EXT = 2'b11;

    // Trigger edge
    localparam  p_edge=1'b0,
                n_edge=1'b1;

    // buffer controller's 'input_rdy' bit, depends on the trigger's source
    assign trigger_source_rdy =     (trigger_source_sel == src_CH1) ? adc_ch1_rdy :
                                    (trigger_source_sel == src_CH2) ? adc_ch2_rdy :
                                    (trigger_source_sel == src_EXT) ? (adc_ch1_rdy | adc_ch2_rdy) :
                                                                  1'b0;

    // Detector Trigger Value = Trigger Value, unless Trigger_Source_Sel == EXT.
    assign trigger_value_out[BITS_ADC-1:0] = (trigger_source_sel == src_EXT) ? (1 << (BITS_ADC-1)) : trigger_value_in[BITS_ADC-1:0];

    // MUX for trigger source selection
    assign tmp_trigger_source[BITS_ADC-1:0] = (trigger_source_sel == src_CH1) ? ch1_in :
                                              (trigger_source_sel == src_CH2) ? ch2_in :
                                              (trigger_source_sel == src_EXT) ? { BITS_ADC{ext_in} } : // sign extension
                                                                            0;

    // Edge type: negate bits to change to negative edge type.
    assign trigger_source_out = (trigger_edge_type == p_edge) ? tmp_trigger_source : ~tmp_trigger_source;


    `ifdef COCOTB_SIM               // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,trigger_input_selector);
            #1;
        end
    `endif

endmodule
