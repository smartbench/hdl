module counter  (
    clk,
    Q
);

    output [7:0] Q;
    input clk;

    parameter cycles_per_second = 100000000;

    reg [32:0] divider;
    reg [7:0] Q;


    always @(posedge clk) begin
       if (divider == cycles_per_second)
         begin
            divider <= 0;
            Q <= Q + 8'd1;
         end
       else  divider <= divider + 1;
    end


endmodule 
