
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
module edge_detector #( parameter BITS_ADC = 8
)(
    input       clk,                // clock
    input       rst,                // asynchronous reset
    input [BITS_ADC-1:0] trigger_value,      // trigger value
    input [BITS_ADC-1:0] input_sample,       // input samples of the trigger source
    input       input_rdy,          // sample available for read
    output reg  triggered         // trigger detected (delays ONE clock)
);

    // Finite State Machine
    reg [1:0] state;            // State register
    localparam  ST_SEARCHING=0,    // First condition not met: waiting for signal to be under (over) trigger value, when ST_SEARCHING for positive (negative) edge
                ST_VALIDATING=1;   // First contition met: signal under (over) trigger value, when ST_SEARCHING for positive (negative) edge

     always @(posedge clk) begin
        triggered <= 1'b0;
        if (rst) begin
            state <= ST_SEARCHING;
        end else if(input_rdy == 1'b1) begin
            case (state)

                ST_SEARCHING:
                    if(input_sample < trigger_value) state <= ST_VALIDATING;

                ST_VALIDATING:
                    if(input_sample >= trigger_value) begin
                        triggered <= 1'b1;
                        state <= ST_SEARCHING;
                    end

                default:
                    state <= ST_SEARCHING;
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
