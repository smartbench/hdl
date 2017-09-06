
`include "HDL_defines.v"

`timescale 1ns/1ps

module ram_controller #(
    parameter RAM_DATA_WIDTH = `__BITS_ADC,
    parameter RAM_SIZE = `__RAM_SIZE_CH    // 1 bloque de 4Kbit (cambiar después...)
)(
    input clk,
    input rst,

    input [RAM_DATA_WIDTH-1:0] din,         // Data input
    input wr_en,                            // Write enable - Controlled by Controller Buffer module
    input si_rdy_adc,                      // Single Interface Ready - Active when there's a sample to be written
    output si_ack_adc,                     // Single Interface Acknkowledge - Active when sample has been written


    input [15:0] n_samples,  // Number of samples to be retrieved after a Request Buffer
    input rqst_buff,                                    // Request buffer
    input data_ack,                                     // Data acknowledge
    output reg [RAM_DATA_WIDTH-1:0] data_out,       // Data output
    output reg data_rdy,                         // Data ready
    output reg data_eof                          // Data End of Frame
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


    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("waveform.vcd");
      $dumpvars (0,ram_controller);
      #1;
    end
    `endif

endmodule
