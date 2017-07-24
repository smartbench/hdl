
/*
    Buffer Controller Module

    This module controls the samples buffer using the edge_detector.
    It's main function is to trigger, respecting the pre-trigger and post-trigger configuration.
    It starts working when the input bit 'start' is set to one, having the following posible states:
        ST_PRE_LOADING:
            This state indicates that the pre_trigger buffer is not full. Won't trigger in this state.
            When the pre_trigger buffer is full, it changes to 'ST_WAITING_TRIGGER'.
        ST_WAITING_TRIGGER:
            Searching for trigger condition. When found, it changes to ST_POST_LOADING to load the remaining samples.
            In 'mode auto', if the trigger condition is not met after N samples, state changes directrly to 'ST_SENDING_DATA',
            and sends whatever it is in the buffer.
        ST_POST_LOADING:
            Loads the remaining samples to complete 'num_samples' samples.
            When finish, changes to 'ST_SENDING_DATA'.
        ST_SENDING_DATA:
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
    NOT TESTED!!

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name                Modified by     Comment


    ToDo:
                Date            Suggested by    Priority    Activity                Description


    Releases:   In development ...

*/

`timescale 1ns/1ps
module buffer_controller  #( parameter BITS_ADC = 8
)(
    input clk,                      // clock
    input rst,                      // asynchronous reset

    // Communication with ADC Controller
    input [BITS_ADC-1:0] input_sample,
    input input_rdy,

    // Communication with RAM Controller
    output write_enable,

    // Communication with Configuration Controller
    input start,                    // start signal inits cycle
    input [15:0] num_samples,       // number of samples to save
    input [15:0] pre_trigger,       // number of samples before trigger
    input [BITS_ADC-1:0] trigger_value,      // trigger value
    input trigger_conf,             // trigger configuration: single, auto

    // Communication with PC_Communication Controller
    output reg send_data_rdy = 1'b0,
    input send_data_ack

);

    localparam  conf_single = 1'b0, // Trigger mode
                conf_auto   = 1'b1;
    localparam  ST_PRE_LOADING=0,
                ST_WAITING_TRIGGER=1,
                ST_POST_LOADING=2,
                ST_SENDING_DATA=3;

    reg [1:0]  state = 2'd0;       // State register
    reg [17:0] counter = 18'd0;    // samples counter
    reg request = 1'b0;            // request made by pc

    wire det_rst;
    wire [BITS_ADC-1:0] detector_input;
    wire triggered;

    // Edge Detector reset unless searching for trigger.
    assign det_rst = (state==ST_WAITING_TRIGGER && request==1'b1) ? 1'b0 : 1'b1;

    assign write_enable = (state != ST_SENDING_DATA) ? 1'b1 : 1'b0;

    // Instantiation of the Edge Detector module
    edge_detector u1(
        .clk(clk),
        .rst(det_rst),
        .trigger_value(trigger_value),
        .input_sample(input_sample),
        .input_rdy(input_rdy),
        .triggered(triggered)
    );

    // Finite State Machine
     always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_PRE_LOADING;
            counter <= 0;
            request <= 1'b0;
        end else begin
            if(start == 1'b1) request <= 1'b1;
            case (state)

                // State to make sure that there are enough
                //  samples in the buffer before triggering
                ST_PRE_LOADING:
                begin
                    if(input_rdy == 1'b1) counter <= counter + 1;
                    if(counter == pre_trigger) begin
                        counter <= 0;
                        state <= ST_WAITING_TRIGGER;
                    end
                end

                // State to search for trigger condition
                ST_WAITING_TRIGGER:
                begin
                    if(input_rdy == 1'b1) counter <= counter + 1;
                    if(triggered == 1'b1) begin
                        request <= 1'b0;
                        counter <= pre_trigger;
                        state <= ST_POST_LOADING;
                    end else begin
                        if( request == 1'b1 &&
                            trigger_conf == conf_auto &&
                            (counter >> 2) == num_samples ) begin
                            // in mode auto, waits for trigger during 4 full buffers. If it doesn't trigger,
                            // then data is sent as it is.
                            request <= 1'b0;
                            send_data_rdy <= 1'b1;
                            state <= ST_SENDING_DATA;
                        end
                    end
                end

                ST_POST_LOADING:
                begin
                    if(counter != num_samples) begin
                        // Loading buffer...
                        if(input_rdy == 1'b1) counter <= counter + 1;
                    end else begin
                        // Buffer loaded, ready to send
                        send_data_rdy <= 1'b1;
                        state <= ST_SENDING_DATA;
                    end
                end

                ST_SENDING_DATA:
                begin
                    if (send_data_ack==1'b1) begin
                        send_data_rdy <= 1'b0;
                        counter <= 0;
                        state <= ST_PRE_LOADING;
                    end
                end

                default:
                begin
                    counter <= 0;
                    request <= 1'b0;
                    state <= ST_PRE_LOADING;
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
