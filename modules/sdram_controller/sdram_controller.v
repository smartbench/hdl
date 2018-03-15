/*
`include "HDL_defines.v"

`timescale 1ns/1ps

module sdram_controller #(
    parameter BANK_ADDR_WIDTH   = `__BANK_ADDR_WIDTH,
    parameter ROW_ADDR_WIDTH    = `__ROW_ADDR_WIDTH,
    parameter COL_ADDR_WIDTH    = `__COL_ADDR_WIDTH,
    parameter ADDR_WIDTH        = BANK_ADDR_WIDTH + ROW_ADDR_WIDTH + COL_ADDR_WIDTH,

    parameter DATA_WIDTH        = `__SDRAM_DATA_WIDTH,
    parameter SIZE              = `__SDRAM_SIZE
)(
    input clk,
    input rst,

    // SI
    input   wire    [ADDR_WIDTH-1:0]    rd_addr,
    input   wire                        rd_ena,
    output  reg     [DATA_WIDTH-1:0]    rd_data,
    output  reg                         rd_rdy,

    input   wire    [ADDR_WIDTH-1:0]    wr_addr,
    input   wire    [DATA_WIDTH-1:0]    wr_data,
    input   wire                        wr_ena,
    output  reg                         wr_ack,

    // SDRAM
    output  reg                         CS#,    // chip select
    output  reg                         RAS#,   // row addr strobe
    output  reg                         CAS#,   // column addr strobe
    output  reg                         WE#,    // write enable
    output  reg                         CKE,    // clock enable
    output  reg                         LDQM,   // Data Input/Output Mask
    output  reg                         UDQM,
    output  reg     [DATA_WIDTH-1:0]    data_rd,
    input   wire    [DATA_WIDTH-1:0]    data_wr,
    input   wire                        bank,
    input   wire    [ROW_ADDR_WIDTH-1:0] addr,

);

    localparam  RAM_ADDR_WIDTH = $clog2(RAM_SIZE/8);

    localparam  ST_WRITING=0,
                ST_SENDING_DATA=1;

    reg [RAM_ADDR_WIDTH-1:0] wr_addr;
    reg [RAM_ADDR_WIDTH-1:0] rd_addr;
    reg [1:0] state;
    reg [15:0] counter;

    wire WE;

    assign WE = (si_rdy_adc == 1'b1 && wr_en == 1'b1 && state == ST_WRITING) ? 1'b1 : 1'b0;
    assign si_ack_adc = WE;

    // RAM Instantiation:
    reg [RAM_DATA_WIDTH-1:0] mem [(1<<RAM_ADDR_WIDTH)-1:0];
    always @(posedge clk)   // Write memory.
        if (WE) mem[wr_addr] <= din; // Using write address bus.
    always @(posedge clk)   // Read memory.
        data_out <= mem[rd_addr]; // Using read address bus.

    // writing
    always @(posedge clk) begin
        //data_eof <= 1'b0;
        if(rst == 1'b1) begin
            data_rdy <= 1'b0;
            data_eof <= 1'b1;
            wr_addr <= 0;
            rd_addr <= 0;
            state <= ST_WRITING;
        end else begin


        end
    end


    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("waveform.vcd");
      $dumpvars (0,ram_controller);
      #1;
    end
    `endif

endmodule
*/
