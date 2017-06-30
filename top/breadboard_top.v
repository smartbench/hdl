//---------------------------------------------------------------------
// Design  : Counter verilog top module, iCEstick (Lattice iCE40)
// Author  : Javier D. Garcia-Lasheras
//---------------------------------------------------------------------

module breadboard_top (
    clock_i,
    led_o_0,
    led_o_1,
    led_o_2,
    led_o_3,
    led_o_4,
    led_o_5,
    led_o_6,
    led_o_7,
);

    input clock_i;
    output led_o_0;
    output led_o_1;
    output led_o_2;
    output led_o_3;
    output led_o_4;
    output led_o_5;
    output led_o_6;
    output led_o_7;
    
    wire clk_100M, s_clear, s_count; 
    wire [7:0] s_Q;
    
    counter u1(
        .clk(clk_100M),
        .Q(s_Q)
    );

    SB_PLL40_CORE #(
            .FEEDBACK_PATH("SIMPLE"),
            .PLLOUT_SELECT("GENCLK"),
            .DIVR(4'b0000),
            .DIVF(7'b1000010),
            .DIVQ(3'b011),
            .FILTER_RANGE(3'b001)
        )uut(
            .RESETB(1'b1),
            .BYPASS(1'b0),
            .REFERENCECLK(clock_i),
            .PLLOUTCORE(clk_100M)
        );

    assign s_clear = 1;
    assign s_count = 1;
    assign led_o_7 = s_Q[7];
    assign led_o_6 = s_Q[6];
    assign led_o_5 = s_Q[5];
    assign led_o_4 = s_Q[4];
    assign led_o_3 = s_Q[3];
    assign led_o_2 = s_Q[2];
    assign led_o_1 = s_Q[1];
    assign led_o_0 = s_Q[0];

endmodule
