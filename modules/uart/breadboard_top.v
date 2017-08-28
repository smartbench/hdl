
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
    input rx,
    output tx
);

    wire clk_100M;
    wire tx_clk, tx_rdy;
    wire rx_clk, rx_ack;
    wire [7:0] s_Q;
    wire [7:0] tx_data;
    wire [7:0] rx_data;
    reg [7:0] data = 0, data_i = 0;

    //uart
    uart u2 #(
        .CLOCK(100e6),
        .BAUDRATE(9600)
    )(
        .clk(clk_100M)
        .rx_clk(rx_clk),

        .tx_data(tx_data),
        .tx_rdy(tx_rdy),
        .tx_ack(tx_ack),

        .rx_data(rx_data),
        .rx_rdy(rx_rdy),
        .rx_ack(rx_ack),

        .tx_enable(1),
        .rx_enable(1),

        .tx(tx),
        .rx(rx)
    );

    // clock uart
    freq_divider u3(
        .clk(clk_100M),
        .tx_clk(tx_clk),
        .rx_clk(rx_clk)
    );

    // combinacional
    assign s_Q = rx_data;

    // secuencial
    always @ (posedge rx_clk) begin
        rx_ack <= 0;
        if(rx_rdy) begin
            rx_ack <= 1;
            data <= { rx_data[7:6], ~rx_data[5:5] , rx_data[4:0]  };
        end
    end

    always @ (posedge tx_clk) begin
        data_i <= data;
        if( tx_data != data_i ) begin
            tx_data <= data_i;
            tx_rdy <= 1;
        end
        if(tx_ack) tx_rdy <= 0;
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
