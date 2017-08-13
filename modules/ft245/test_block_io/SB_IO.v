

`timescale 1ns/1ps

module SB_IO #(
    parameter PIN_TYPE = 6'b 101001,
    parameter  PULLUP = 1'b0
    )(
       inout PACKAGE_PIN ,
       input LATCH_INPUT_VALUE,
       input CLOCK_ENABLE,
       input INPUT_CLK,
       output OUTPUT_CLK,
       input OUTPUT_ENABLE,
       input D_OUT_0,
       input D_OUT_1,
       output D_IN_0,
       output D_IN_1
);

    assign PACKAGE_PIN = OUTPUT_ENABLE ? D_OUT_0 : 8'bzzzzzzzz ; // To drive the inout net
    assign D_IN_0 = PACKAGE_PIN;

endmodule
