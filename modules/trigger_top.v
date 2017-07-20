
/*
    Trigger top module

    This module coordinates the trigger sub-modules.
    The requests are made from the computer, whenever it's available for printing.
    This applies to both the two ways of working:
    A) Single: Waits until trigger condition is met. After trigger, fills the data buffer, which is sent to the computer.
    B) Auto: Similar to single, but if trigger condition is not met after 4*num_samples, sends the data buffer as it is.
    The equivalent to the single mode in an oscilloscope is implemented with a single request from the computer, with this module in 'single' mode.
    The equivalent to the normal mode in an oscilloscope is implemented with several requests from the computer, with this module in 'single' mode.
    The equivalent to the automatic mode in an oscilloscope is implemented with several requests from the computer, with this module in 'auto' mode.

    Note #1:

    IMPORTANT:
    Since at the moment (2017/07/19) the controlled enviroment for testbench is
    not developed, this was NOT TESTED!

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name            Modified by     Comment
                2017/07/19      0.1             Trigger_top     AK              First version. UNTESTED!

    ToDo:
                Date            Suggested by    Priority    Activity                Description
                2017/07/19      AK              High        TEST                    Make testbench!
                2017/07/19      AK              Low         Add complexity          ...

    Releases:   In development ...

*/

module trigger_detection  (
    clk,                // clock
    reset,              // asynchronous reset
    enable,             // enable crossing detection
    run,                // run signal inits cycle
    ch1_in,
    ch2_in,
    ext_in,
    ch1_out,
    ch2_out,
    write_enable,       // indicates whether or not the outputs should be written in RAM
    finished,           // indicates full buffer written, available to send.
    num_samples,        // number of samples to save
    pre_trigger,        // number of samples before trigger
    trigger_source,     // trigger source: CH1, CH2, EXT, ...
    trigger_conf,       // trigger configuration: single, auto
    trigger_edge,       // positive or negative edge
    trigger_value,      // trigger value
);
    input           clk, reset, enable;
    output          write_enable, finished;
    input [7:0]     ch1_in, ch2_in, ext_in;
    output [7:0]    ch1_out, ch2_out;
    input [15:0]    num_samples, pre_trigger;
    input [1:0]     trigger_source;
    input           trigger_conf;
    input [7:0]     trigger_value;
    input           trigger_edge;
        
    wire [15:0] first_sample;
    
    // testing behaviour... not sure if necessary...
    wire signed [16:0] signed_pre_trigger;
    wire signed [16:0] signed_current_sample;
    wire signed [16:0] signed_num_samples;
    wire signed [16:0] signed_first_sample;
    assign signed_current_sample = current_sample;  // sign extension
    assign signed_num_samples = num_samples;        // sign extension
    assign signed_pre_trigger = pre_trigger;        // sign extension
    assign first_sample[15:0] = signed_first_sample[15:0];  
    //

    // Configuration:
    parameter   src_XXX = 2'b00,
                src_CH1 = 2'b01,
                src_CH2 = 2'b10,
                src_EXT = 2'b11;
    parameter   conf_single = 1'b0,
                conf_auto   = 1'b1;

    wire [15:0] post_trigger;
    assign post_trigger = num_samples - pre_trigger;
    reg [15:0] trigger_sample, current_sample, mem_position;
    //assign {carry,sum} = a+b

    // Instantiation of trigger detection module
    trigger_detection u1(
        .clk(clk),
        .reset(det_reset)
        .enable(det_enable)
        .input_sample(input_sample),
        .trigger_edge(trigger_edge),
        .trigger_value(det_trigger_value),
        .triggered(triggered)
    );

    wire det_reset, det_enable, triggered, trigger_found = 1'b0;
    wire [15:0] input_sample;

    case (trigger_source)
        src_XXX:
            input_sample[7:0] <= 8'b0;
            det_trigger_value[7:0] <= trigger_value[7:0];
        src_CH1:
            input_sample[7:0] <= ch1_in;
            det_trigger_value[7:0] <= trigger_value[7:0];
        src_CH2:
            input_sample[7:0] <= ch2_in;
            det_trigger_value[7:0] <= trigger_value[7:0];
        src_EXT:
            input_sample[7:0] <= {ext_in, 7'b0000000};
            det_trigger_value[7:0] <= 8'b01000000;
    endcase

    // Finite State Machine
    reg [1:0] state;                // State register
    parameter   available=0,
                pre_loading=1,
                waiting_trigger=2,
                post_loading=3,
                sending_data=4;

     always @(posedge clk or posedge reset) begin
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
        if (reset) begin
            state <= available;
            current_sample <= 0;
            det_reset <= 1'b1;
        end else begin
            if (enable==1'b0) begin
                state <= available;
                current_sample <= 0;
                det_reset <= 1'b1;
            end else begin
                case (state)
                    available:
                        if(start == 1'b1) begin
                            state <= pre_loading;
                            write_enable <= 1'b1;
                        end
                        
                    pre_loading:    // State to make sure that there are enough samples in the buffer
                                    //  before trigger.
                        current_sample <= current_sample + 1;
                        if(current_sample == pre_trigger) state <= waiting_trigger;

                    waiting_trigger:
                        current_sample <= current_sample + 1;
                        if(triggered == 1'b1) begin
                            //first_sample[15:0] <= current_sample[15:0] - pre_trigger[15:0]; //delay trigger = 0... check!
                            signed_first_sample <= signed_current_sample - signed_pre_trigger;
                            det_reset <= 1'b1;
                            state <= post_loading;
                        end else begin
                            // in mode auto, waits for trigger during 4 full buffers. If it doesn't trigger,
                            // then data is sent as it is.
                            if(trigger_conf == conf_auto && num_samples == (current_sample >> 2)) begin
                                det_enable <= 1'b1;
                                write_enable <= 1'b0;   // Stops writing RAM
                                signed_first_sample <= signed_current_sample - signed_num_samples;
                                state <= sending_data;
                            end
                        end
                    
                    post_loading:
                        current_sample <= current_sample + 1;
                        if(pre_trigger + current_sample - trigger_sample == num_samples) begin
                            det_enable <= 1'b1;
                            write_enable <= 1'b0;   // Stops writing RAM
                            state <= sending_data;
                        end

                    sending_data:
                        // ... Send data ...

                        // ... when finish:
                        if (1==1) begin // change condition!
                            state <= available;
                            current_sample <= 0;
                            det_reset <= 1'b1;
                        end

                    default:
                        state <= available;
                        current_sample <= 0;
                        det_reset <= 1'b1;
                endcase
            end
        end
    end

endmodule
