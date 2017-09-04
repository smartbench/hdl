
`include "conf_regs_defines.v"

`timescale 1ns/1ps

module ram_controller #(
    parameter RAM_DATA_WIDTH = `__BITS_ADC,
    parameter RAM_SIZE = `__RAM_SIZE_CH    // 1 bloque de 4Kbit (cambiar después...)
)(
    input clk,
    input rst,
    
    // Input (Buffer Controller)
    input wr_en,
    input rqst_chA_data,
    input rqst_chB_data,
    input n_samples,
    
    // Internal (ADC)
    input si_data_adc_chA,
    input si_rdy_adc_chA,
    output si_ack_adc_chA, //not used!

    input si_data_adc_chB,
    input si_rdy_adc_chB,
    output si_ack_adc_chB, //not used!
    
    // Output (Tx Protocol)
    output data_out,
    output data_rdy,
    output data_eof,
    input data_ack,

    // RAM INTERFACE
    input clk_i,
    input rst,

    // "PSEUDO DUAL PORT" INTERNAL INTERFACE

    input [ADDR_WIDTH-1:0] waddr,
    input [DATA_WIDTH-1:0] wdata,
        
    input we,
    
    input [ADDR_WIDTH-1:0] raddr,
    output reg [DATA_WIDTH-1:0] rdata,
    
    // Simple interface ready/ack logic
    input rdy,
    output reg ack,

    // RAM INTERFACE

    output clk_o,
    output reg clke,

    input [DATA_WIDTH-1:0] data_i,
    output reg [DATA_WIDTH-1:0] data_o,
    output reg [ADDR_BUS_WIDTH-1:0] addr,

    output reg csn,
    output reg rasn,
    output reg casn,
    output reg wen,
    
    output reg LDQM,
    output reg UDQM
);

    localparam  RAM_ADDR_WIDTH = $clog2(RAM_SIZE/8);

    localparam  ST_WRITING=0,
                ST_SENDING_DATA=1;

    reg [RAM_ADDR_WIDTH-1:0] wr_addr;
    reg [RAM_ADDR_WIDTH-1:0] rd_addr;
    reg [1:0] state;
    reg [15:0] counter;

    wire WE;
    wire ram_rdy;
    wire ram_ack; //not used

    assign WE = (si_rdy_adc == 1'b1 && wr_en == 1'b1 && state == ST_WRITING) ? 1'b1 : 1'b0;
    assign si_ack_adc = WE;
    //assign ram_rdy = ( state == ST_WRITING ) ? WE : data_rdy;

    localparam FIFO_DATA_WIDTH = 8;
    localparam FIFO_ADDR_WIDTH = 9;

    // RAM Instantiation:
    reg [FIFO_DATA_WIDTH-1:0] fifo [(1<<FIFO_ADDR_WIDTH)-1:0];
    reg fifo_wr_addr;
    reg fifo_rd_addr;
    reg fifo_empty;
    reg fifo_full;

    always @( posedge clk ) begin
        if( rst ) begin
            fifo_wr_addr <= { FIFO_ADDR_WIDTH{1'b0} };
            fifo_rd_addr <= { FIFO_ADDR_WIDTH{1'b0} };
            fifo_empty <= 1'b1;
            fifo_full <= 1'b0;
        end else begin

            if( WE && !fifo_full) begin
                fifo[fifo_wr_addr] <= din;
                fifo_empty <= 1'b0;
                fifo_wr_addr = fifo_wr_addr + (FIFO_ADDR_WIDTH)'b1 ;    // bloquing assignement, for readability
                if( fifo_wr_addr == fifo_rd_addr  ) begin
                    fifo_full <= 1'b1;
                end
            end

            if( ram_ack && !fifo_empty ) begin
                ram_data_i <= fifo[fifo_rd_addr];                       // Using read address bus.
                fifo_full <= 1'b0;
                fifo_rd_addr = fifo_rd_addr + (FIFO_ADDR_WIDTH)'b1;     // bloquing assignement, for readability
                if( fifo_rd_addr == fifo_wr_addr ) begin
                    fifo_empty <= 1'b1;
                end
            end

        end
    end

    // writing
    always @(posedge clk) begin

        if(rst == 1'b1) begin
            wr_addr <= 0;
            rd_addr <= 0;
            data_rdy <= 1'b0;
            data_eof <= 1'b1;
            state <= ST_WRITING;
            counter <= 0;
        end else begin

            case(state)
                ST_WRITING:
                begin
                    if(rqst_buff == 1'b1) begin
                        counter <= n_samples;
                        state <= ST_SENDING_DATA;
                    end else if(WE == 1'b1) begin
                        wr_addr <= wr_addr + 1;
                        rd_addr <= wr_addr; // last written addr
                    end

                end

                ST_SENDING_DATA:
                begin
                    data_eof <= 1'b0;
                    data_rdy <= 1'b1;        // always ready, ram reading never delays.
                    if(data_ack == 1'b1) begin
                        data_rdy <= 1'b0;
                        rd_addr <= rd_addr - 1;
                        counter <= counter - 1;
                        if(counter == 1) begin
                            data_rdy <= 1'b0;
                            data_eof <= 1'b1;
                            rd_addr <= wr_addr - 1; // last written addr
                            state <= ST_WRITING;
                        end
                    end
                end
            endcase
        end
    end

    module SDRAM #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(20), // Total addr width
        .ADDR_BUS_WIDTH(12) // Physical bus width
    ) sdram_u (

        .clk_i      (clk),
        .rst        (rst),

        .waddr      (wr_addr),
        .wdata      (din),
        .we         (wr_en),
        
        .raddr      (rd_addr),
        .rdata      (data_out),
        
        .rdy        (ram_rdy),
        .ack        (ram_ack),

        .clk_o      (clk_o),
        .clke       (clke),

        .data_i     (data_i),
        .data_o     (data_o),
        .addr       (addr),

        .csn        (csn),
        .rasn       (rasn),
        .casn       (casn),
        .wen        (wen),
        
        .LDQM       (LDQM),
        .UDQM       (UDQM)
    );

    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("waveform.vcd");
      $dumpvars (0,ram_controller);
      #1;
    end
    `endif

endmodule
