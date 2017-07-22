
/*
    Edge detector module

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
module edge_detector  (
    input       clk,                // clock
    input       rst,                // asynchronous reset
    input [7:0] trigger_value,      // trigger value
    input [7:0] input_sample,       // input samples of the trigger source
    input       in_ena,             // sample available for read
    output      triggered=0         // trigger detected (delays ONE clock)
);
    parameter CLOCK_PERIOD_NS = 10;

    // Finite State Machine
    reg [1:0] state;            // State register
    localparam  searching=0,    // First condition not met: waiting for signal to be under (over) trigger value, when searching for positive (negative) edge
                validating=1;   // First contition met: signal under (over) trigger value, when searching for positive (negative) edge

     always @(posedge clk or posedge rst) begin
        triggered <= 1'b0;
        if (rst)
            state <= searching;
        else begin
            case (state)

                searching:
                    if(input_sample < trigger_value) state <= validating;

                validating:
                    if(input_sample >= trigger_value) begin
                        state <= searching;
                        triggered <= 1'b1;
                    end

                default:
                    state <= searching;
            endcase
        end
    end

    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("waveform.vcd");
      $dumpvars (0,edge_detector);
      #1;
    end
    `endif

endmodule
