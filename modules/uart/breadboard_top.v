
module breadboard_top (
    input clock_i,
    output led_o_0,
    output led_o_1,
    output led_o_2,
    output led_o_3,
    output led_o_4,
    output led_o_5,
    output led_o_6,
    output led_o_7,
    input rx_in,
    output tx_out
);

    wire clk_100M;
    wire tx_clk, tx_out, ld_tx_data, tx_empty;
    wire rx_clk, rx_in, uld_rx_data, rx_empty;
    wire [7:0] s_Q;
    wire [7:0] tx_data;
    wire [7:0] rx_data;
    reg [7:0] data;

    //uart
    uart u2(
        .txclk(tx_clk),
        .tx_enable(1),
        .tx_data(tx_data), /*.tx_data(s_Q),*/
        .tx_empty(tx_empty),
        .ld_tx_data(ld_tx_data),
        .tx_out(tx_out),

        .rxclk(rx_clk),
        .rx_data(rx_data),
        .uld_rx_data(uld_rx_data),
        .rx_empty(rx_empty),
        .rx_enable(1),
        .rx_in(rx_in)
    );

    // clock uart
    freq_divider u3(
        .clk(clk_100M),
        .tx_clk(tx_clk),
        .rx_clk(rx_clk)
    );

    // combinacional
    assign s_Q = rx_data;
    always @ (s_Q[7:0]) begin
        tx_data[7:0] = s_Q[7:0];
        tx_data[5] = ~s_Q[5];
    end

    // secuencial
    always @ (posedge rx_clk) begin
        uld_rx_data <= 0;
        if(!rx_empty) uld_rx_data <= 1;
    end

    always @ (posedge tx_clk) begin
        ld_tx_data <= 0;
        if ( tx_empty && !(data[7:0] == s_Q[7:0]) ) begin
            ld_tx_data <= 1;
            data[7:0] <= s_Q[7:0];
        end
    end

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

    assign led_o_7 = s_Q[7];
    assign led_o_6 = s_Q[6];
    assign led_o_5 = s_Q[5];
    assign led_o_4 = s_Q[4];
    assign led_o_3 = s_Q[3];
    assign led_o_2 = s_Q[2];
    assign led_o_1 = s_Q[1];
    assign led_o_0 = s_Q[0];

endmodule
