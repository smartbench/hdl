/*
*   Author: Iván Paunovic
*
* This module translate usb configuration messages to I2C dac voltages.
* The computer directly sent the 4 bytes needed ( 2 bytes per message ).
* This module detec */

`include "HDL_defines.v"

module i2c_wrapper #(
    parameter REGISTER_ADDR_WIDTH = `__REG_ADDR_WIDTH,
    parameter REGISTER_DATA_WIDTH = `__REG_DATA_WIDTH,
    parameter DAC_I2C_REGISTER_ADDR = `__ADDR_DAC_I2C,
    parameter DAC_I2C_REGISTER_DEFAULT = `__DEFAULT_DAC_I2C,
    parameter I2C_CLOCK_DIVIDER = 1000,
    parameter I2C_FIFO_LENGTH = 4
)(
    input clk,
    input rst,

    /* Register interface */
    input [REGISTER_ADDR_WIDTH-1:0] register_addr,
    input [REGISTER_DATA_WIDTH-1:0] register_data,
    input register_rdy,

    /* Dac interface */
    output scl,
    inout sda_io //
);

    /* Simulated OPENDRAIN with tristate buffer and pullup
     * Buffer input is always 1'b0.
     * Output is enabled with ~sda_out.
     * So output is LOW when sda_o is 0 and is tri-stated when sda_o is 1.*/

    wire sda_in, sda_out;

    SB_IO #(
        .PIN_TYPE(6'b101001),
        .PULLUP(1'b1)
    ) IO_PIN_INST (
        .PACKAGE_PIN (sda_io),
        .LATCH_INPUT_VALUE (),
        .CLOCK_ENABLE (),
        .INPUT_CLK (),
        .OUTPUT_CLK (),
        .OUTPUT_ENABLE (~sda_out),
        .D_OUT_0 (1'b0),
        .D_OUT_1 (),
        .D_IN_0 (sda_in),
        .D_IN_1 ()
    );

    /* DAC_A and DAC_B register VALUES */

    wire [REGISTER_DATA_WIDTH-1:0] data;
    wire rdy;
    wire [7:0] fifo_in;
    reg start;
    reg data_start_d;

    always @(posedge clk) data_start_d <= data[8];
    always @* start <= ~data_start_d & data[8];
    assign fifo_in = data[7:0];


    fully_associative_register #(
        .REG_ADDR_WIDTH     (REGISTER_ADDR_WIDTH),
        .REG_DATA_WIDTH     (REGISTER_DATA_WIDTH),
        .MY_ADDR        (DAC_I2C_REGISTER_ADDR),
        .MY_RESET_VALUE (DAC_I2C_REGISTER_DEFAULT)
    ) reg_dac_i2c (
        .clk            (clk),
        .rst            (rst),
        .si_addr        (register_addr),
        .si_data        (register_data),
        .si_rdy         (register_rdy),
        .data           (data),
        .new_data       (rdy)
    );

    /* I2C Master Controller */

    wire ended, ack;

    i2c #(
        .I2C_CLOCK_DIVIDER      (I2C_CLOCK_DIVIDER),
        .FIFO_LENGTH            (I2C_FIFO_LENGTH) //,
    ) i2c_i(
        .clk        (clk),
        .rst        (rst),

        .fifo_in    (fifo_in),
        .rdy        (rdy),

        .start      (start),

        .sda_out    (sda_out),
        .sda_in     (sda_in),
        .scl        (scl)
    );

    `ifdef COCOTB_SIM
    initial begin
      $dumpfile ("waveform.vcd");
      $dumpvars (0,i2c_wrapper);
      #1;
    end
    `endif

endmodule
