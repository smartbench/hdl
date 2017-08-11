
`timescale 1ns/1ps

module ft245_block #(
    parameter FT245_DATA_WIDTH = `FT245_DATA_WIDTH,
    parameter RX_WIDTH = `RX_WIDTH,
    parameter TX_WIDTH = `TX_WIDTH
)( 
    // 
    input clk,
    input rst,

    inout [FT245_DATA_WIDTH-1:0] ftdi_data,
    
    // ft245 rx interface
    input rxf_245,
    output rx_245,
    // ft245 tx interface
    input txe_245,
    output wr_245,

    // simple interface
    output [RX_WIDTH-1:0] rx_data_si,
    output rx_rdy_si,
    input rx_ack_si,

    input [TX_WIDTH-1:0] tx_data_si,
    input tx_rdy_si,
    output tx_ack_si


);
    
    defparam my_generic_IO.PIN_TYPE = 6’b{4'b1010, 2'b01};
    
    wire tx_oe_245;
    wire [FT245_DATA_WIDTH-1:0] tx_data_245;
    wire [FT245_DATA_WIDTH-1:0] rx_data_245;
    
    genvar h;
    generate
        for (h=0 ; h<FT245_DATA_WIDTH ; h=h+1) begin
            SB_IO IO_PIN_INST(
                .PACKAGE_PIN (ftdi_data[h]),
                .LATCH_INPUT_VALUE (),
                .CLOCK_ENABLE (),
                .INPUT_CLK (),
                .OUTPUT_CLK (),
                .OUTPUT_ENABLE (tx_oe_245),
                .D_OUT_0 (rx_data_245[h]),
                .D_OUT_1 (),
                .D_IN_0 (tx_data_245[h]),
                .D_IN_1 ()
            );
        end
    endgenerate
    
    
    ft245_interface #(
        .CLOCK_PERIOD_NS(10.0)
    ) ft245_interface_u ( 
        .clk(clk),
        .rst(rst),
        .rx_data_245(rx_data_245),
        .rxf_245(rxf_245),
        .rx_245(rx_245),
        // ft245 tx interface
        .tx_data_245(tx_data_245),
        .txe_245(txe_245),
        .wr_245(wr_245),
        .tx_oe_245(tx_oe_245),
        // simple interface
        .rx_data_si(rx_data_si),
        .rx_rdy_si(rx_rdy_si),
        .rx_ack_si(rx_ack_si),
        .tx_data_si(tx_data_si),
        .tx_rdy_si(tx_rdy_si),
        .tx_ack_si(tx_ack_si)
    );



`ifdef COCOTB_SIM
initial begin
  $dumpfile ("waveform.vcd");
  $dumpvars (0,ft245_block);
  #1;
end
`endif

endmodule
