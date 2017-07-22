module freq_divider (
    clk,
    tx_clk,
    rx_clk
);

    input clk;
    output tx_clk;
    output rx_clk;
    
    // clock in = 100MHz
    // baudrate = 9600
    parameter rx_div = 651; // 100e6/(9600*16) = 651

    reg [13:0] rx_divider;
    reg [3:0] cont;
    

    always @(posedge clk) begin
        if (rx_divider == rx_div) begin
            rx_divider <= 0;
            rx_clk <= 1'b1;
            cont <= cont + 1;
            if(cont == 0) tx_clk <= 1'b1;
            else tx_clk <= 1'b0;
        end
        else begin
            rx_divider <= rx_divider + 1;
            rx_clk <= 1'b0;
        end
    end

endmodule 
