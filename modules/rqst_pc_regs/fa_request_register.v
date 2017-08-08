
/*
    A simple fully associative request register.

    The module checks if the addr bus is equal to the register addr.
    Value is updated when the condition is true.
    When data is acknowledged, the register is erased.

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name                Modified by         Comment
                2017/07/23      0.1             request_reg         IP                  Module created.
                2017/07/26      0.2             request_reg         AK                  Changes in ACK behaviour

    ToDo:
                Date            Suggested by    Priority    Activity                Description
                2017/07/26      AK              Medium      Remove ACK              It's useless. The requests' handler
                                                                                    module is continuously reading data.
                                                                                    It forces an OR of the data array (see
                                                                                    requests_pc_handler.v)


    Releases:   In development ...
*/

`timescale 1ns/1ps

module fa_request_register #(
    parameter ADDR_WIDTH = `__REG_ADDR_WIDTH,
    parameter DATA_WIDTH = `__REG_DATA_WIDTH,
    parameter MY_ADDR = 0,
    parameter MY_RESET_VALUE = 0
) (
    // Basic signals
    input clk,
    input rst,

    // Address and data simple interface
    input [ADDR_WIDTH-1:0] si_addr,
    input [DATA_WIDTH-1:0] si_data,
    input si_rdy,

    // Register value
    input data_ack,
    output reg [DATA_WIDTH-1:0] data
);

    always @( posedge(clk) ) begin
        if ( rst == 1'b1 ) begin
            data <= MY_RESET_VALUE;
        end else begin
            if ( data_ack == 1'b1 ) data <= MY_RESET_VALUE; //moved here because if ack==1 but also
                                                            // rdy==1 && addr=MY_ADDR, it should be written
            if ( si_rdy == 1'b1 && si_addr == MY_ADDR ) begin
                if (data_ack == 1'b1) data <= si_data;  // if data was ACKed, then overwrites.
                else data <= data | si_data;            // if data wasn't ACKed (or register already in reset value),
                                                        //  the new requests are added to the current ones.
            end
        end
    end
endmodule
