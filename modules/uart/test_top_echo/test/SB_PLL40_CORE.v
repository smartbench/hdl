
// test file, PLL

module SB_PLL40_CORE #(
    // default values for 100MHz
    parameter FEEDBACK_PATH = "SIMPLE",
    parameter PLLOUT_SELECT = "GENCLK",
    parameter [3:0] DIVR = 4'b0,
    parameter [6:0] DIVF = 7'b1000010,
    parameter [2:0] DIVQ = 3'b011,
    parameter [2:0] FILTER_RANGE = 3'b001
)(
    input RESETB,
    input BYPASS,
    input REFERENCECLK,
    output PLLOUTCORE,
    output LOCK
);

    // a wire for tests!
    assign PLLOUTCORE = REFERENCECLK;
    assign LOCK = 1'b1;

endmodule
