`timescale 1ns/1ps
// `include "SB_RAM512x8.v"
// `include "/usr/local/share/yosys/ice40/brams_map.v"
// `define EBR_SIZE (8*512)

module ram_interface_2 #(
    parameter RAM_DATA_WIDTH = 8,
    parameter RAM_SIZE = (4096*4),    // 1 bloque de 4Kbit (cambiar después...)
    parameter RAM_ADDR_WIDTH = $clog2(RAM_SIZE/8)
)(
    input clk,
    input rst,

    input [RAM_DATA_WIDTH-1:0] din,         // Data input
    input wr_en,                            // Write enable - Controlled by Controller Buffer module
    input si_rdy_adc,                      // Single Interface Ready - Active when there's a sample to be written
    output si_ack_adc,                     // Single Interface Acknkowledge - Active when sample has been written


    input [15:0] n_samples,  // Number of samples to be retrieved after a Request Buffer
    input rqst_buff,                                    // Request buffer
    input rd_en,                                        // Read enable
    output [RAM_DATA_WIDTH-1:0] dout,                   // Data output
    output reg EOF = 1'b0
);

    wire WE;

    reg [RAM_ADDR_WIDTH-1:0] wr_addr = 0;
    reg [RAM_ADDR_WIDTH-1:0] rd_addr = 0;
    reg [1:0] state = 0;
    reg [15:0] counter = 0;

    localparam  ST_WRITING=0,
                ST_SENDING_DATA=1;

    SB_RAM512x8 #(
        .ADDR_WIDTH (RAM_ADDR_WIDTH),
        .DATA_WIDTH (RAM_DATA_WIDTH)
    )ram512x8_inst (
        .dout       (dout),
        .raddr      (rd_addr), // Less significative bits of rd_cont_addr
        .rclk       (clk),
        .waddr      (wr_addr), // Less significative bits of wr_cont_addr
        .wclk       (clk),
        .din        (din),
        .write_en   (WE)
    );

    assign WE = (si_rdy_adc && wr_en && state == ST_WRITING);

    assign si_ack_adc = WE;

    // writing
    always @(posedge clk) begin
        EOF <= 1'b0;
        if(rst == 1'b1) begin
            wr_addr <= 0;
            rd_addr <= 0;
            state <= ST_WRITING;
        end else begin
            case(state)

                ST_WRITING:
                begin
                    if(si_rdy_adc == 1'b1) begin
                        wr_addr <= wr_addr + 1;
                        rd_addr <= wr_addr; // last written addr
                    end
                    if(rqst_buff == 1'b1) begin
                        counter <= n_samples;
                        state <= ST_SENDING_DATA;
                    end
                end

                ST_SENDING_DATA:
                begin
                    if(rd_en == 1'b1) begin
                        rd_addr <= rd_addr - 1;
                        counter <= counter - 1;
                        if(counter == 1) begin
                            EOF <= 1'b1;
                            rd_addr <= wr_addr - 1; // last written addr
                            state <= ST_WRITING;
                        end
                    end
                end

            endcase

            // ...
        end
    end


    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("waveform.vcd");
      $dumpvars (0,ram_interface_2);
      #1;
    end
    `endif

endmodule
