`timescale 1ns/1ps

module ram_interface #(
  parameter RAM_DEPTH = 512,
  parameter RAM_DATA_WIDTH = 8,
  parameter RAM_BLOCK_DATA_WIDTH = 512,
  parameter RAM_BLOCK_ADDR_WIDTH = 9,

  parameter RAM_ADDR_WIDTH = $clog2(RAM_DEPTH),
  parameter RAM_NUM_OF_SB_RAM512x8_BLOCKS = RAM_DEPTH % 512,
  parameter RAM_MAX_RQST_BUFF_SIZE = RAM_DEPTH // TODO-> Review if this parameter is really necessary
)(
  input [RAM_DATA_WIDTH-1:0] din,         // Data input
  input wr_en,                            // Write enable - Controlled by Controller Buffer module
  input si_rdy_adcX,                      // Single Interface Ready - Active when there's a sample to be written
  output si_ack_adcX,                     // Single Interface Acknkowledge - Active when sample has been written

  input rqst_buff,                                    // Request buffer
  input rd_en,                                        // Read enable
  input n_samples [$ctlog2(MAX_RQST_BUFF_SIZE)-1:0],  // Number of samples to be retrieved after a Request Buffer
  output reg [DATA_WIDTH-1:0] dout,                   // Data output

  input rst,
  input clk,
  );

  reg [RAM_ADDR_WIDTH-1:0] wr_addr = 0;
  reg [RAM_ADDR_WIDTH-1:0] rd_addr = 0;

  wire [RAM_DATA_WIDTH-1:0] din_array [0:RAM_NUM_OF_SB_RAM512x8_BLOCKS-1];
  wire [RAM_DATA_WIDTH-1:0] dout_array [0:RAM_NUM_OF_SB_RAM512x8_BLOCKS-1];
  // reg [RAM_BLOCK_DATA_WIDTH-1:0] wr_cont_addr = (RAM_BLOCK_DATA_WIDTH-1)'b0;
  // reg [RAM_BLOCK_DATA_WIDTH-1:0] rd_cont_addr = (RAM_BLOCK_DATA_WIDTH-1)'b0; //
  reg [$clog2(RAM_NUM_OF_SB_RAM512x8_BLOCKS)-1:0] wr_blk = 0;
  reg [$clog2(RAM_NUM_OF_SB_RAM512x8_BLOCKS)-1:0] wr_blk = 0;


  genvar i;
  generate
    for (i=0; i<RAM_NUM_OF_SB_RAM512x8_BLOCKS ; i++)
    begin : RAM_BLK
      SB_RAM512x8 ram512X8_inst (
        .RDATA  (dout_array[i]),
        .RADDR  (rd_cont_addr[RAM_BLOCK_DATA_WIDTH-1:0]),
        .RCLK   (clk),
        .RCLKE  (rd_en),
        .RE     (rd_en), // Shouldn't exists according to "Memeroy... for iCE40 Devices page 2"
        .WADDR  (wr_cont_addr),
        .WCLK   (clk),
        .WCLKE  (si_rdy_adcX),
        .WDATA  (din_array[i]),
        .WE     (wr_en)
      );
    end
  endgenerate

  // Generate MUX module to address the correct block
  always @ ( * ) begin
    for(j=0; j<RAM_NUM_OF_SB_RAM512x8_BLOCKS; j++)
      if (wr_addr[RAM_ADDR_WIDTH-1:RAM_BLOCK_ADDR_WIDTH] ==i) begin

      end
    end
  end


  always @ (posedge clk ) begin
    if (wr_en==1'b1 && si_rdy_adcX==1'b1) begin
      // Data is written in the correct RAM_BLOCK. Check the combinational description
      // So just de addres needs to incremented
      wr_addr <= wr_addr + 1'b1;
    end

    if () // Reading 

    if (rst == 1'b1) begin // TODO complete!
      wr_cont_addr <= 0;
      rd_cont_addr <= 0;
    end
  end







`ifdef COCOTB_SIM
initial begin
  $dumpfile ("waveform.vcd");
  $dumpvars (0,ram_interface);
  #1;
end
`endif

endmodule
