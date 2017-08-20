
/*
    Buffer Controller Module

    This module controls the samples buffer using the edge_detector.
    It's main function is to trigger, respecting the pre-trigger and post-trigger configuration.
    It starts working when the input bit 'start' is set to one, having the following posible states:
        ST_IDLE:
            This is the only state where 'write_enable' bit is keep at zero, to avoid writing in the buffer until
            data is correctly sent to the computer.
        ST_PRE_LOADING:
            This state indicates that the pre_trigger buffer is not full. Won't trigger in this state.
            When the pre_trigger buffer is full, it changes to 'ST_WAITING_TRIGGER'.
        ST_WAITING_TRIGGER:
            Waiting for trigger condition.
            When reaches num_samples, buffer_full_o turns to 1.
            When found, it changes to ST_POST_LOADING to load the remaining samples. In this case, buffer_full_o is reset to zero, and triggered=1.
        ST_POST_LOADING:
            Loads the remaining samples to complete 'num_samples' samples.
            When finished, buffer_full_o=1, changes to 'ST_IDLE'.


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

module buffer_controller  #(
    parameter BITS_ADC = 8
)(
    input clk,                      // clock
    input rst,                      // synchronous reset

    // Trigger input source
    input [BITS_ADC-1:0] input_sample,
    input input_rdy,

    // Configuration
    input [15:0] num_samples,       // number of samples to save
    input [15:0] pre_trigger,       // number of samples before trigger
    input [BITS_ADC-1:0] trigger_value,      // trigger value

    // Requests
    input start,                // start signal inits cycle
    input stop,                 // unused so far!!
    input rqst_trigger_status,

    // Communication with RAM Controller
    output write_enable,

    // Communication with tx_control
                  //

    output reg [7:0] trigger_status_data = 8'd0, // output frame [7:0] = {x,x,x,x,x,x,triggered_o,buffer_full_o}
    output reg trigger_status_rdy = 1'b0,
    output reg trigger_status_eof = 1'b1,        // end of frame
    input trigger_status_ack
);

    localparam  ST_IDLE = 0,
                ST_PRE_LOADING = 1,
                ST_WAITING_TRIGGER = 2,
                ST_POST_LOADING = 3;

    reg [1:0]  state = 2'd0;       // State register
    reg [17:0] counter = 18'd0;    // samples counter

    reg triggered_o = 1'b0;
    reg buffer_full_o = 1'b0;

    wire edge_detector_rst;
    wire triggered;

    // Edge Detector reset unless searching for trigger.
    assign edge_detector_rst = (state==ST_WAITING_TRIGGER) ? 1'b0 : 1'b1;

    assign write_enable = (state != ST_IDLE) ? 1'b1 : 1'b0;

    // Instantiation of the Edge Detector module
    edge_detector u1(
        .clk(clk),
        .rst(edge_detector_rst),
        .trigger_value(trigger_value),
        .input_sample(input_sample),
        .input_rdy(input_rdy),
        .triggered(triggered)
    );

    // Finite State Machine
     always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            buffer_full_o <= 1'b0;
            triggered_o <= 1'b0;
            state <= ST_IDLE;
        end else begin
            if(input_rdy == 1'b1) counter <= counter + 1;

            if (start == 1'b1) begin
                counter <= 0;
                buffer_full_o <= 1'b0;
                triggered_o <= 1'b0;
                state <= ST_PRE_LOADING;
            end else if(stop == 1'b1) begin
                state <= ST_IDLE;
            end else begin
                case (state)

                    ST_IDLE:
                    begin
                        // yep, nothing here.
                        // Start changes state
                    end

                    // State to make sure that there are enough
                    //  samples in the buffer before triggering
                    ST_PRE_LOADING:
                    begin
                        if(counter == pre_trigger) state <= ST_WAITING_TRIGGER;
                    end

                    // State to search for trigger condition
                    ST_WAITING_TRIGGER:
                    begin
                        if( counter == num_samples ) buffer_full_o <= 1'b1;
                        if( triggered == 1'b1 ) begin
                            counter <= pre_trigger;     // force to count from "pre_trigger" samples.
                            buffer_full_o <= 1'b0;    // When triggers, resets buffer_full_o to wait for post-trigger samples
                            triggered_o <= 1'b1;
                            state <= ST_POST_LOADING;
                        end
                    end

                    ST_POST_LOADING:
                    begin
                        if(counter == num_samples) begin
                            buffer_full_o <= 1'b1;
                            state <= ST_IDLE;
                        end
                    end

                    default:
                    begin
                        counter <= 0;
                        buffer_full_o <= 1'b0;
                        triggered_o <= 1'b0;
                        state <= ST_IDLE;
                    end
                endcase
            end
        end
    end

    // Tx Protocol
    localparam  ST2_IDLE=0,
                ST2_SENDING=1;
    reg state_2 = ST2_IDLE;

    //assign trigger_status_eof = (trigger_status_ack == 1'b1 || trigger_status_rdy == 1'b0) ? 1'b1 : 1'b0;

    // comm with tx_control
    always @(posedge clk) begin
        trigger_status_data[0] <= buffer_full_o;
        trigger_status_data[1] <= triggered_o;
        if(rst == 1'b1) begin
            trigger_status_rdy <= 1'b0;
            trigger_status_eof <= 1'b1;
        end else begin
            case(state_2)

                ST2_IDLE:
                begin
                    if(rqst_trigger_status == 1'b1) begin
                        trigger_status_rdy <= 1'b1;
                        trigger_status_eof <= 1'b0;
                        state_2 <= ST2_SENDING;
                    end
                end

                ST2_SENDING:
                begin
                    if(trigger_status_ack == 1'b1) begin
                        trigger_status_eof <= 1'b1;
                        trigger_status_rdy <= 1'b0;
                        state_2 <= ST2_IDLE;
                    end
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
