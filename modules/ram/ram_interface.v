`timescale 1ns/1ps
// `include "SB_RAM512x8.v"
// `include "/usr/local/share/yosys/ice40/brams_map.v"

module ram_interface #(
  parameter RAM_DEPTH = 8192,
  parameter RAM_DATA_WIDTH = 8,
  parameter RAM_BLOCK_DATA_WIDTH = 512,
  parameter RAM_BLOCK_ADDR_WIDTH = 9,

  parameter RAM_ADDR_WIDTH = $clog2(RAM_DEPTH),
  parameter RAM_NUM_OF_SB_RAM512x8_BLOCKS = RAM_DEPTH / 512,
  parameter RAM_MAX_RQST_BUFF_SIZE = RAM_DEPTH // TODO-> Review if this parameter is really necessary
)(
  input [RAM_DATA_WIDTH-1:0] din,         // Data input
  input wr_en,                            // Write enable - Controlled by Controller Buffer module
  input si_rdy_adcX,                      // Single Interface Ready - Active when there's a sample to be written
  output si_ack_adcX,                     // Single Interface Acknkowledge - Active when sample has been written

  input rqst_buff,                                    // Request buffer
  input rd_en,                                        // Read enable
  input [$clog2(RAM_MAX_RQST_BUFF_SIZE)-1:0] n_samples,  // Number of samples to be retrieved after a Request Buffer
  output reg [RAM_DATA_WIDTH-1:0] dout,                   // Data output

  input rst,
  input clk,
  );

  reg [RAM_ADDR_WIDTH-1:0] wr_addr = 0;
  reg [RAM_ADDR_WIDTH-1:0] rd_addr = 0;

  wire [RAM_DATA_WIDTH-1:0] din_array [0:RAM_NUM_OF_SB_RAM512x8_BLOCKS-1];
  wire [RAM_DATA_WIDTH-1:0] dout_array [0:RAM_NUM_OF_SB_RAM512x8_BLOCKS-1];
  reg [RAM_ADDR_WIDTH-1:0] wr_cont_addr = (RAM_ADDR_WIDTH)'b0;
  reg [RAM_ADDR_WIDTH-1:0] rd_cont_addr = (RAM_ADDR_WIDTH)'b0;
  //reg [$clog2(RAM_NUM_OF_SB_RAM512x8_BLOCKS)-1:0] wr_blk = ($clog2(RAM_NUM_OF_SB_RAM512x8_BLOCKS))'b0;
  // reg [$clog2(RAM_NUM_OF_SB_RAM512x8_BLOCKS)-1:0] wr_blk = ($clog2(RAM_NUM_OF_SB_RAM512x8_BLOCKS))'b0;

  wire [RAM_NUM_OF_SB_RAM512x8_BLOCKS-1:0] wr_en_array;
  wire [RAM_NUM_OF_SB_RAM512x8_BLOCKS-1:0] wr_clk_en_array;
  wire [RAM_NUM_OF_SB_RAM512x8_BLOCKS-1:0] rd_en_array;
  wire [RAM_NUM_OF_SB_RAM512x8_BLOCKS-1:0] rd_clk_en_array;

  reg [$clog2(RAM_NUM_OF_SB_RAM512x8_BLOCKS)-1:0] wr_blk_ram_sel = 0;
  reg [$clog2(RAM_NUM_OF_SB_RAM512x8_BLOCKS)-1:0] rd_blk_ram_sel = 0;
  reg [$clog2(RAM_NUM_OF_SB_RAM512x8_BLOCKS)-1:0] j = 0;

  localparam  READ_MODE = 1;
  localparam  WRITE_MODE = 1;


  // Esto NO anda
  genvar i;
  generate
    for (i=0; i<RAM_NUM_OF_SB_RAM512x8_BLOCKS ; i=i+1)  begin : ram_label
    
      SB_RAM40_4K #(
  			.READ_MODE(0),
  			.WRITE_MODE(1)
  		) block_ram (
  			.RDATA(dout_array[i]),
  			.RCLK (clk ),
  			.RCLKE(rclke), // shouldn't be available for 512x8 ram
  			.RE   (rclke), // shouldn't be available for 512x8 ram
  			.RADDR(rd_cont_addr [ADDR_WIDTH-1:0]),
  			.WCLK (clk ),
  			.WCLKE(wr_en),
  			.WE   (wr_en),
  			.WADDR(wr_cont_addr [ADDR_WIDTH-1:0]),
  			.MASK (0),
  			.WDATA(din_array[i])
  		);

   end
  endgenerate

  assign dout = dout_array[0];

    // Generate MUX module to address the correct block
    always @ ( * ) begin
        wr_blk_ram_sel = wr_cont_addr % RAM_BLOCK_ADDR_WIDTH;
        rd_blk_ram_sel = rd_cont_addr % RAM_BLOCK_ADDR_WIDTH;
        for (j=0; j<RAM_NUM_OF_SB_RAM512x8_BLOCKS ; j++) begin
            if (j==wr_blk_ram_sel) begin
              wr_en_array[j] = wr_en;
              wr_clk_en_array[j] = si_rdy_adcX;
            end else begin
              wr_en_array[j] = 1'b0;
              wr_clk_en_array[j] = 1'b0;
            end
            if (j==rd_blk_ram_sel) begin
              rd_en_array[j] = rd_en;   // TODO check enables when reading
              rd_clk_en_array[j] = rd_en;
            end else begin
              rd_en_array[j] = 1'b0;
              rd_clk_en_array[j] = 1'b0;
            end
        end
    end


    always @ (posedge clk ) begin
        if (wr_en==1'b1 && si_rdy_adcX==1'b1) begin
            //Data is written to the correct RAM_BLOCK. Check the combinational description.
            //Just the addres needs to incremented.
            wr_cont_addr <= wr_cont_addr + 1'b1;
        end
        if (rd_en==1'b1 && rqst_buff==1'b1) begin // Reading
            //Similar to writing. Read the above description.
            if(rd_cont_addr==n_samples) begin
              rd_cont_addr<=0;
            end
            rd_cont_addr <= rd_cont_addr + 1'b1;
        end
        if (rst==1'b1) begin
            rd_cont_addr <= 0;
            rd_cont_addr <= 0;
        end
    end


  // Esto NO anda
  // genvar i;
  // generate
  //   for (i=0; i<4 ; i++)
  //   begin : label
  //       SB_RAM40_4K #(
  //     		.READ_MODE(1),
  //     		.WRITE_MODE(1)
  //     	) ram40_00 (
  //     		.WADDR  (wr_cont_addr),
  //     		.RADDR  (rd_cont_addr),
  //     		.MASK   (0),
  //     		.WDATA  (din),
  //     		.RDATA  (dout),
  //     		.WE     (wr_en),
  //     		.WCLKE  (1'b1),
  //     		.WCLK   (clk),
  //     		.RE     (1'b1),
  //     		.RCLKE  (1'b1),
  //     		.RCLK   (clk),
  //     );
  //   end
  // endgenerate


// Esto lo instancia, cuando paso al for genarate No
/*
   SB_RAM40_4K #(
 		.READ_MODE(0),
 		.WRITE_MODE(1)
 	) ram40_00 (
 		.WADDR  (wr_cont_addr),
		.RADDR  (rd_cont_addr),
 		.MASK   (0),
 		.WDATA  (din),
 		.RDATA  (dout),
 		.WE     (wr_en),
 		.WCLKE  (1'b1),
 		.WCLK   (clk),
 		.RE     (1'b1),
 		.RCLKE  (1'b1),
 		.RCLK   (clk)
 );
 */
//
// SB_RAM40_4K #(
//   .READ_MODE(0),
//   .WRITE_MODE(1)
// ) ram40_01 (
//   .WADDR  (wr_cont_addr),
//   .RADDR  (rd_cont_addr),
//   .MASK   (0),
//   .WDATA  (din),
//   .RDATA  (dout),
//   .WE     (wr_en),
//   .WCLKE  (1'b1),
//   .WCLK   (clk),
//   .RE     (1'b1),
//   .RCLKE  (1'b1),
//   .RCLK   (clk)
// );




  // SB_RAM512x8 #(
  //   .ADDR_WIDTH (11),
  //   .DATA_WIDTH (8)
  // )ram512x8_inst (
  //   .dout       (dout[RAM_DATA_WIDTH-1:0]),
  //   .raddr      (rd_cont_addr[RAM_BLOCK_ADDR_WIDTH-1:0]), // Less significative bits of rd_cont_addr
  //   .rclk       (clk),
  //   .waddr      (wr_cont_addr[RAM_BLOCK_ADDR_WIDTH-1:0]), // Less significative bits of wr_cont_addr
  //   .wclk       (clk),
  //   .din        (din[RAM_DATA_WIDTH-1:0]),
  //   .write_en   (wr_en)
  // );





  // genvar i;
  // generate
  //   for (i=0; i<RAM_NUM_OF_SB_RAM512x8_BLOCKS ; i++)
  //   begin : RAM_BLK
  //     SB_RAM512x8 ram512X8_inst (
  //       .RDATA  (dout[RAM_DATA_WIDTH-1:0]),
  //       .RADDR  (rd_cont_addr[RAM_BLOCK_ADDR_WIDTH-1:0]), // Less significative bits of rd_cont_addr
  //       .RCLK   (clk),
  //       .RCLKE  (rd_clk_en_array[i]),
  //       .RE     (rd_en_array[i]), // Shouldn't exists according to "Memeroy... for iCE40 Devices" page 2
  //       .WADDR  (wr_cont_addr[RAM_BLOCK_ADDR_WIDTH-1:0]), // Less significative bits of wr_cont_addr
  //       .WCLK   (clk),
  //       .WCLKE  (wr_clk_en_array[i]),
  //       .WDATA  (din[RAM_DATA_WIDTH-1:0]),
  //       .WE     (wr_en_array)
  //     );
  //   end
  // endgenerate

  // Generate MUX module to address the correct block
  // always @ ( * ) begin
  //   wr_blk_ram_sel = wr_cont_addr % RAM_BLOCK_ADDR_WIDTH;
  //   rd_blk_ram_sel = rd_cont_addr % RAM_BLOCK_ADDR_WIDTH;
  //
  //   for (j=0; j<RAM_NUM_OF_SB_RAM512x8_BLOCKS ; j++) begin
  //     if (j==wr_blk_ram_sel) begin
  //       wr_en_array[j] = wr_en;
  //       wr_clk_en_array[j] = si_rdy_adcX;
  //     end else begin
  //       wr_en_array[j] = 1'b0;
  //       wr_clk_en_array[j] = 1'b0;
  //     end
  //
  //     if (j==rd_blk_ram_sel) begin
  //       rd_en_array[j] = rd_en;     // TODO check enables when reading
  //       rd_clk_en_array[j] = rd_en;
  //     end else begin
  //       rd_en_array[j] = 1'b0;
  //       rd_clk_en_array[j] = 1'b0;
  //     end
  //   end
  // end


  // always @ (posedge clk ) begin
  //   if (wr_en==1'b1 && si_rdy_adcX==1'b1) begin
  //     // Data is written to the correct RAM_BLOCK. Check the combinational description.
  //     // Just the addres needs to incremented.
  //     wr_cont_addr <= wr_cont_addr + 1'b1;
  //   end
  //
  //   if (rd_en==1'b1 && rqst_buff==1'b1) // Reading
  //     // Similar to writing. Read the above description.
  //     if(rd_cont_addr==n_samples) begin
  //       rd_cont_addr<=0;
  //     end
  //     rd_cont_addr <= rd_cont_addr + 1'b1;
  //   end
  //
  //   // if (rst==1'b1) begin
  //   //   rd_cont_addr<=0;
  //   //   // rd_cont_addr <= '0;
  //   // end
  // end







`ifdef COCOTB_SIM
initial begin
  $dumpfile ("waveform.vcd");
  $dumpvars (0,ram_interface);
  #1;
end
`endif

endmodule
