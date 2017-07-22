
/*
    Buffer Controller Module

    This module controls the samples buffer using the edge_detector.
    It's main function is to trigger, respecting the pre-trigger and post-trigger configuration.
    It starts working when the input bit 'start' is set to one, having the following posible states:
        st_pre_loading:
            This state indicates that the pre_trigger buffer is not full. Won't trigger in this state.
            When the pre_trigger buffer is full, it changes to 'st_waiting_trigger'.
        st_waiting_trigger:
            Searching for trigger condition. When found, it changes to st_post_loading to load the remaining samples.
            In 'mode auto', if the trigger condition is not met after N samples, state changes directrly to 'st_sending_data',
            and sends whatever it is in the buffer.
        st_post_loading:
            Loads the remaining samples to complete 'num_samples' samples.
            When finish, changes to 'st_sending_data'.
        st_sending_data:
            This is the only state (besides when rst==1) where 'write_enable' bit is keep at zero, to avoid writing in the buffer until
            data is correctly sent to the computer.

    Trigger modes explained:
    The requests are made from the computer, whenever it's available for printing.
    This applies to both the two ways of working:
    A) Single: Waits until trigger condition is met. After trigger, fills the data buffer, which is sent to the computer.
    B) Auto: Similar to single, but if the trigger condition is not met after 4*num_samples, the data in the buffer is sent anyway as it is.
    The equivalent to the single mode in an oscilloscope is implemented with a single request from the computer, with this module in 'single' mode.
    The equivalent to the normal mode in an oscilloscope is implemented with several requests from the computer, with this module in 'single' mode.
    The equivalent to the automatic mode in an oscilloscope is implemented with several requests from the computer, with this module in 'auto' mode.

    Note #1:
    The edge_type selection (positive or negative) is not done in the edge_detector module anymore.
    Now the negative edge detection is simply archieved by a bitwise negation of the samples from where the edge_detector is fed.

    Interconnections:
    This module will interconnect with:
    - RAM Controller
    - ADC Controller
    - Configuration Controller
    - PC_Communication Controller ()

    IMPORTANT:
    Testbench: basic testbench was done, but not all the posibilities were covered.

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name                Modified by     Comment
                2017/07/19      0.10            Trigger_top         AK              First version. UNTESTED!
                2017/07/22      0.11            buffer_controller   AK              Basic testbench successfull.

    ToDo:
                Date            Suggested by    Priority    Activity                Description
                2017/07/22      AK              High        TEST                    More tests!
                2017/07/22      AK              Medium      Add complexity          ...

    Releases:   In development ...

*/

`timescale 1ns/1ps
module buffer_controller  (
    input clk,                      // clock
    input rst,                      // asynchronous reset

    // Communication with ADC Controller
    input [7:0] ch1_in,
    input [7:0] ch2_in,
    input ext_in,
    input in_ena,                   //

    // Communication with RAM Controller
    output reg [7:0] ch1_out = 0,
    output reg [7:0] ch2_out = 0,
    output reg write_enable = 0,            // indicates whether or not the outputs should be written in RAM

    // Communication with Configuration Controller
    input start,                    // start signal inits cycle
    input [15:0] num_samples,       // number of samples to save
    input [15:0] pre_trigger,       // number of samples before trigger
    input [1:0] trigger_source,     // trigger source: CH1, CH2, EXT, ...
    input [7:0] trigger_value,      // trigger value
    input trigger_conf,             // trigger configuration: single, auto
    input edge_type,                // positive or negative edge

    // Communication with PC_Communication Controller
    input data_sent,
    output reg send_data = 0
);

    // Configuration:
    localparam  src_XXX = 2'b00,    // Trigger source
                src_CH1 = 2'b01,
                src_CH2 = 2'b10,
                src_EXT = 2'b11;
    localparam  conf_single = 1'b0, // Trigger mode
                conf_auto   = 1'b1;
    localparam  positive_edge=1'b0, // Trigger edge
                negative_edge=1'b1;
    reg [1:0]   state = 2'b0;       // State register
    parameter   st_pre_loading=0,
                st_waiting_trigger=1,
                st_post_loading=2,
                st_sending_data=3;


    // testing behaviour... not sure if necessary...
    wire signed [16:0] signed_pre_trigger;
    wire signed [16:0] signed_current_sample;
    wire signed [16:0] signed_num_samples;

    wire det_rst;
    wire [7:0] input_sample;
    wire [7:0]det_input;
    wire [7:0] det_trigger_value;
    wire triggered;

    reg signed [16:0] signed_first_sample = 16'd0;  // start of the window
    reg [15:0] current_sample = 16'd0;              // samples counter
    reg request = 1'b0;                             // request made by pc

    assign signed_current_sample = current_sample;  // sign extension
    assign signed_num_samples = num_samples;        // sign extension
    assign signed_pre_trigger = pre_trigger;        // sign extension

    // MUX for trigger source selection
    assign input_sample[7:0] =  (trigger_source == src_CH1) ? ch1_in :
                                (trigger_source == src_CH2) ? ch2_in :
                                (trigger_source == src_EXT) ? {ext_in, 7'b0000000} :
                                8'b0;
    // Edge type: negate bits to change to negative edge type.
    assign det_input = (edge_type == positive_edge) ? input_sample : ~input_sample;

    // Detector Trigger Value = Trigger Value, unless Trigger Source == EXT.
    //  When EXT source, Trigger Value = 64, and input_sample = {ext_in , 7'b0000000}.
    //  This way the ext_in controlls the MSB of input_sample, so when it turns from 0 to 1,
    //  (or 1 to 0) it'll cross the Trigger Value (128)
    assign det_trigger_value[7:0] = (trigger_source == src_EXT) ? 8'b01000000 : trigger_value[7:0];

    // Edge Detector reset unless searching for trigger.
    assign det_rst = (state==st_waiting_trigger && request==1'b1) ? 1'b0 : 1'b1;

    // Instantiation of the Edge Detector module
    edge_detector u1(
        .clk(clk),
        .rst(det_rst),
        .trigger_value(det_trigger_value),
        .input_sample(det_input),
        .in_ena(in_ena),
        .triggered(triggered)
    );

    // Finite State Machine
     always @(posedge clk or posedge rst) begin
        // Muahahahahahaha... so it begins...
        // Should I put a safety pig over here, Andy??
        /*
        ch1_in_i <= ch1_in;
        ch2_in_i <= ch2_in;
        ch1_out <= ch1_in_i;
        ch2_out <= ch2_in_i;
        */
        // Delay to sync with write_enable output bit
        ch1_out <= ch1_in;
        ch2_out <= ch2_in;
        // .............................
        write_enable <= 1'b0;
        if (rst) begin
            state <= st_pre_loading;
            current_sample <= 0;
            request <= 1'b0;
        end else begin
            // Start bit enables cycle.
            if(start == 1'b1) request <= 1'b1;
            case (state)

                // State to make sure that there are enough
                //  samples in the buffer before triggering
                st_pre_loading: begin
                    if(in_ena == 1'b1) begin
                        write_enable <= 1'b1;
                        current_sample <= current_sample + 1;
                    end
                    if(current_sample == pre_trigger) state <= st_waiting_trigger;
                end

                // State to search for trigger condition
                st_waiting_trigger:
                begin
                    if(in_ena == 1'b1) begin
                        current_sample <= current_sample + 1;
                        write_enable <= 1'b1;
                    end
                    if(triggered == 1'b1) begin
                        signed_first_sample <= signed_current_sample - signed_pre_trigger;
                        state <= st_post_loading;
                        if(start == 1'b0) request <= 1'b0;
                    end else begin
                        // in mode auto, waits for trigger during 4 full buffers. If it doesn't trigger,
                        // then data is sent as it is.
                        if(trigger_conf == conf_auto && num_samples == (current_sample >> 2)) begin
                            signed_first_sample <= signed_current_sample - signed_num_samples;
                            write_enable <= 1'b0;
                            if(start == 1'b0) request <= 1'b0;
                            state <= st_sending_data;
                            send_data <= 1'b1;
                        end
                    end
                end

                st_post_loading:
                begin
                    if(signed_current_sample - signed_first_sample != signed_num_samples) begin
                        if(in_ena == 1'b1) begin
                            write_enable <= 1'b1;
                            current_sample <= current_sample + 1;
                        end
                    end else begin
                        state <= st_sending_data;
                        send_data <= 1'b1;
                    end
                end

                st_sending_data:
                begin
                    if (data_sent==1'b1) begin
                        state <= st_pre_loading;
                        current_sample <= 0;
                    end
                end

                default:
                begin
                    state <= st_pre_loading;
                    current_sample <= 0;
                end
            endcase
        end
    end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("waveform.vcd");
  $dumpvars (0,buffer_controller);
  #1;
end
`endif

endmodule
