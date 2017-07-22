
/*
    Trigger detection module

    This module detects when the input signal crosses a determinated value.
    It can be configured to detect positive and negative edges.
    The output is a single bit that becames one during one clock each time the
    crossing condition is met.

    Note #1:
    This module only detects the crossing. The logic involving the selection of
    the source of trigger belongs outside this module.

    Note #2:
    The current implementation (0.1) has a delay of 1 (ONE) sample, meaning that
    a crossing detection corresponds to a previous sample.

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
                2017/07/19      0.1             Crossing        AK              First version. UNTESTED!

    ToDo:
                Date            Suggested by    Priority    Activity                Description
                2017/07/19      AK              High        TEST                    Make testbench!
                2017/07/19      AK              Low         Add complexity          Filter, avoid false detections due to noise

    Releases:   In development ...

*/
`timescale 1ns/1ps
module trigger_detection  (
    input       clk,                // clock
    input       reset,              // asynchronous reset
    input       trigger_edge,       // positive or negative edge
    input [7:0] trigger_value,      // trigger value
    input [7:0] input_sample,       // input samples of the trigger source
    input       in_ena,             // sample available for read
    output      out_ena=0,          // valid output sample
    output      triggered=0         // trigger detected
);
    parameter CLOCK_PERIOD_NS = 10;

    // Configured edge
    localparam positive_edge=1'b0, negative_edge=1'b1;

    // Finite State Machine
    reg [1:0] state;            // State register
    localparam  disabled=0,     // Detection disabled.
                searching=1,    // First condition not met: waiting for signal to be under (over) trigger value, when searching for positive (negative) edge
                validating=2,   // First contition met: signal under (over) trigger value, when searching for positive (negative) edge
                found=3;        // Second condition met: Signal crossed the trigger value.

     always @(posedge clk or posedge reset) begin
        triggered <= 1'b0;
        if (reset) begin
            state <= disabled;
            out_ena <= 1'b0;
        end else begin
            out_ena <= in_ena;
            case (state)

                disabled:
                    state <= searching;

                searching:
                    case (trigger_edge)
                     positive_edge:
                         if(input_sample < trigger_value) state <= validating;
                     negative_edge:
                         if(input_sample > trigger_value) state <= validating;
                    endcase

                validating:
                    case (trigger_edge)
                     positive_edge:
                        if(input_sample >= trigger_value) begin
                            state <= searching;
                            triggered <= 1'b1;
                        end
                     negative_edge:
                        if(input_sample <= trigger_value) begin
                            state <= searching;
                            triggered <= 1'b1;
                        end
                    endcase

                default:
                    state <= searching;
            endcase
        end
    end

    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("waveform.vcd");
      $dumpvars (0,trigger_detection);
      #1;
    end
    `endif

endmodule
