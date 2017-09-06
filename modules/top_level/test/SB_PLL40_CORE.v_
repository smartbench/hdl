
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
    output reg LOCK = 0
);

    // a wire for tests!
    assign PLLOUTCORE = REFERENCECLK;
    reg [3:0] counter = 0;
    always @(posedge REFERENCECLK) begin
        counter <= counter - 1;
        if (counter == 1) LOCK <= 1;
    end

endmodule
