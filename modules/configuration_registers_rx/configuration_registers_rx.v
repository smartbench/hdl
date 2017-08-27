/*

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name            Modified by     Comment
                2017/07/23      0.1             regsBegin       IP              First approach

    ToDo:
                Date            Suggested by    Priority    Activity                Description

    Releases:   In development ...
*/

`timescale 1ns/1ps

module configuration_registers_rx #(
    parameter RX_DATA_WIDTH = 8,        // FIFO data width
    parameter REG_ADDR_WIDTH = 8,
    parameter REG_DATA_WIDTH = 16
) (

    // Basic
    input clk,                                      // fpga clock
    input rst,                                      // synch reset

    // Simple interface rx data
    input [RX_DATA_WIDTH-1:0] rx_data,              // data
    input rx_rdy,                                   // ready
    output rx_ack,                                  // acknowledgment

    // Simple interface register data
    output [REG_DATA_WIDTH-1:0] register_data,      // data
    output [REG_ADDR_WIDTH-1:0] register_addr,      // ready
    output reg register_rdy                         // ready
);

    // Register data is formed by REG_DATA_PACKETS number of  FIFO data
    localparam REG_DATA_PACKETS = REG_DATA_WIDTH / RX_DATA_WIDTH;
    // Register width is formed by REG_DATA_PACKETS number of  FIFO data
    localparam REG_ADDR_PACKETS = REG_ADDR_WIDTH / RX_DATA_WIDTH;
    //
    // // Local parameters
    // local parameter REG_ADDR_WIDTH = REG_ADDR_PACKETS * RX_DATA_WIDTH ;
    // local parameter REG_DATA_WIDTH = REG_DATA_PACKETS * RX_DATA_WIDTH ;

    // Data and address divided by packets. This is easier to read.
    reg [RX_DATA_WIDTH-1:0] register_data_pck [REG_DATA_PACKETS-1:0];
    reg [RX_DATA_WIDTH-1:0] register_addr_pck [REG_ADDR_PACKETS-1:0];

    // Packet counter
    reg [$clog2(REG_ADDR_PACKETS+REG_DATA_PACKETS)-1:0 ] count = 0;

    // States local parameters
    localparam ST_RECEIVING_ADDR = 0;
    localparam ST_RECEIVING_DATA = 1;

    // State register
    reg state = ST_RECEIVING_ADDR;

    // Flattened the arrays of packets in the data bits (this is why register_data and register_addr are wires)
    genvar i;
    generate
        for( i=0; i<REG_DATA_PACKETS; i=i+1 ) assign register_data[(i+1)*RX_DATA_WIDTH-1:i*RX_DATA_WIDTH] = register_data_pck[i];
        for( i=0; i<REG_ADDR_PACKETS; i=i+1 ) assign register_addr[ ((i+1)*RX_DATA_WIDTH-1): i*RX_DATA_WIDTH ] = register_addr_pck[i];
    endgenerate

    // Asynch assigment of rx_ack; equal rx_rdy except we are waiting to be acknowledged
    assign rx_ack = rx_rdy;

    always @(posedge(clk)) begin

        register_rdy <= 1'b0;

        if ( rst == 1'b1 ) begin
            count <= 0;
            state <= ST_RECEIVING_ADDR;
        end else begin
            case (state)

                ST_RECEIVING_ADDR:
                begin
                    if ( rx_rdy == 1'b1 ) begin
                        register_addr_pck[count] <= rx_data;
                        if( count == REG_ADDR_PACKETS-1 ) begin
                            count <= 0;
                            state <= ST_RECEIVING_DATA;
                        end else begin
                            count <= count + 1;
                        end
                    end
                end

                ST_RECEIVING_DATA:
                begin
                    if ( rx_rdy == 1'b1 ) begin
                        register_data_pck[count] <= rx_data;
                        if( count == REG_DATA_PACKETS-1 ) begin
                            register_rdy <= 1;
                            count <= 0;
                            state <= ST_RECEIVING_ADDR;
                        end else begin
                            count <= count + 1;
                        end
                    end
                end

            endcase
        end
    end

    `ifdef COCOTB_SIM           // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,configuration_registers_rx);
            #1;
        end
    `endif

endmodule
