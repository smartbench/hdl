/*
*   Authors:
*       Iván Paunovic
*       Ariel Kukulanski
*
*   This is a simple I2C masters that only writes to slaves devices.
*   It can't read and also it's not allowed a multimaster solution.
*
*   Internal interface:
*
*   input fifo_in[7:0]
*   input n_bytes[7:0]
*   input rdy
*
*   output ended
*   output ack
*
*   I2C bus interface:
*
*   output sda_out
*   input sda_in
*   output SCL
*
*   Behaviour:
*
*   When rdy is HIGH, the controller save fifo_in byte in an internal
*   fifo. An internal fifo_write_direction pointer is increased in each
*   data input.
*   The value stored in n_bytes is only checked in the first byte frame and indicates how many bytes after that one will complete the i2c frames from start to stop.
*   When all the bytes of a frame are available, the transmission is started.
*   The transmission ends when all of those frame were sent, or when a byte was not acknowledged by the slave.
*
*
*   Restart condition is not implemented.
*
*   Slave address and R/W bit is part of the bytes message written
*   on the fifo and not supervised by this simple controller.
*
*/

`timescale 1ns/1ps

`include "HDL_defines.v"

module i2c_alt #(
    parameter I2C_CLOCK_DIVIDER = `__I2C_CLOCK_DIVIDER,
    parameter FIFO_LENGTH = `__I2C_FIFO_LENGTH //,

)(
    input clk,
    input rst,

    input wire [7:0] fifo_in,
    input wire [7:0] n_bytes,
    input wire rdy,
    output reg fifo_overflow,

    // input wire start,
    output reg ended,
    output reg ack,

    output reg sda_out,
    input sda_in,
    output reg scl
);


/* fifo and fifo pointers */
reg [7:0] fifo [0:FIFO_LENGTH-1];
reg [7:0] fifo_n_bytes [0:FIFO_LENGTH-1];

localparam POINTER_WIDTH = $clog2(FIFO_LENGTH);
reg [POINTER_WIDTH-1:0] read_pointer;
reg [POINTER_WIDTH-1:0] write_pointer;

/* bit pointer */
reg [2:0] nbit;

/* state machine parameters and register */
localparam ST_IDLE = 0;
localparam ST_START = 1;
localparam ST_BYTE = 2;
localparam ST_WAITING_ACK = 3;
localparam ST_CHECKING_ACK = 4;
localparam ST_PREPAIRING_STOP = 5;
localparam ST_ASSERTING_STOP = 6;
localparam  ST_OK_MESSAGE = 7;
localparam  ST_ERROR_MESSAGE = 8;

localparam ST_NUMBER = 9;
localparam ST_WIDTH = $clog2( ST_NUMBER-1 );

reg [ST_WIDTH-1:0] state;

/* Timing definitions, and timing counter */
// localparam MAX_WAITING_TIME_NS = 4700;
// localparam MAX_COUNT = $rtoi( $ceil( $itor( MAX_WAITING_TIME_NS ) / CLOCK_ns ) );
// localparam COUNTER_WIDTH = $clog2( MAX_COUNT );
//
// localparam START_THOLD_TIME = 4000;
// localparam STOP_TSETUP_TIME = 4000;
// localparam STOP_THOLD_TIME = 4000;

//localparam START_THOLD_COUNT = $rtoi( $ceil( $itor( START_THOLD_TIME ) / CLOCK_ns ) );

/* Clock generation*/
localparam MAX_CLOCK_DIVISOR_COUNT = I2C_CLOCK_DIVIDER/2;
localparam CLOCK_DIVISOR_COUNTER_WIDTH = $clog2( MAX_CLOCK_DIVISOR_COUNT );
reg clock_enable;
reg [CLOCK_DIVISOR_COUNTER_WIDTH-1:0] clock_divisor_counter;
reg scl_d;

wire [7:0] bytes_to_wait;
assign bytes_to_wait = fifo_n_bytes[read_pointer];
localparam ONE_WIDTH_POINTER = { { (POINTER_WIDTH-1) {1'b0} }, 1'b1 };

/* Counters and clock division logic logic */
always @( posedge clk ) begin
    if( rst ) begin
        clock_divisor_counter <= { CLOCK_DIVISOR_COUNTER_WIDTH {1'b0} };
        scl <= 1'b1;
        scl_d <= 1'b0;
    end else begin
        scl_d <= scl;
        if( clock_enable ) begin
            clock_divisor_counter <= clock_divisor_counter + { { (CLOCK_DIVISOR_COUNTER_WIDTH-1) {1'b0} }, 1'b1 };
            if( clock_divisor_counter == ( MAX_CLOCK_DIVISOR_COUNT-1 )  ) begin
                scl <= ~scl;
                clock_divisor_counter <= { CLOCK_DIVISOR_COUNTER_WIDTH {1'b0} };
            end
        end
    end
end

/* Fifo save logic */

always @( posedge clk ) begin
    if( rst ) begin
        write_pointer   <= { POINTER_WIDTH {1'b0} };
        fifo_overflow   <= 1'b0;
    end else begin
        if ( rdy ) begin
            write_pointer <= write_pointer + ONE_WIDTH_POINTER;
            if( write_pointer + ONE_WIDTH_POINTER == read_pointer) begin
                fifo_overflow <= 1'b1;
            end
        end
    end
end

genvar i;
generate
for( i=0; i<FIFO_LENGTH; i = i+1 ) begin: fifo_register
    always @( posedge clk ) begin
        if( rst ) begin
            fifo[i]         <= 8'd0;
            fifo_n_bytes[i] <= 8'd0;
        end else begin
            if ( rdy ) begin
                // fifo registers are writen in a fully associative way
                if( write_pointer == i ) begin
                    fifo[i]         <= fifo_in;
                    fifo_n_bytes[i] <= n_bytes;
                end
            end
        end
    end
end
endgenerate


reg scl_negedge;
reg scl_posedge;
always @* scl_negedge <= ~scl & scl_d;
always @* scl_posedge <= scl & ~scl_d;

reg [POINTER_WIDTH-1:0] count;

/* I2C Master state machine */
always @( posedge clk ) begin
    if( rst ) begin
        sda_out <= 1'b1;
        ended   <= 1'b0;
        nbit    <= 3'd7;
        state   <= ST_IDLE;
        ack     <= 1'b0;
        count   <= 0;
        aaa     <= 0;
        clock_enable <= 1'b0;
        read_pointer <= { POINTER_WIDTH { 1'b0 } };
    end else begin
        ended   <= 1'b0;
        ack     <= 1'b0;
        // sending state machine logic
        case( state )

            ST_IDLE:
            begin
                // if( start && read_pointer != write_pointer ) begin
                if(write_pointer-read_pointer > bytes_to_wait) begin
                    count       <= bytes_to_wait;
                    state       <= ST_START;
                    sda_out     <= 1'b0;
                    clock_enable <= 1'b1;
                end
            end

            ST_START:
            begin
                if( scl_negedge ) begin
                    sda_out     <= fifo[read_pointer][nbit];
                    nbit        <= 3'd6;
                    state       <= ST_BYTE;
                end
            end

            ST_BYTE:
            begin
                // Wait half the clock low time to change sda, in order to don't have setup or hold time problems.
                if( scl_negedge ) begin
                    sda_out     <= fifo[read_pointer][nbit];
                    nbit        <= nbit - 3'b1;
                end

                if( scl_posedge && ( nbit == 3'd7 ) ) begin
                    state       <= ST_WAITING_ACK;
                end
            end

            ST_WAITING_ACK:
            begin
                if( scl_negedge ) begin
                    state       <= ST_CHECKING_ACK;
                    sda_out     <= 1'b1;
                end
            end

            ST_CHECKING_ACK:
            begin
                if( scl_posedge ) begin
                    if( !sda_in ) begin // acked
                        read_pointer    <= read_pointer + ONE_WIDTH_POINTER;
                        //if( read_pointer != (write_pointer - { { (POINTER_WIDTH-1) {1'b0} }, 1'b1 } ) ) begin
                        if (count > 0) begin // more bytes to send
                            count   <= count - ONE_WIDTH_POINTER;
                            state   <= ST_START;
                        end else begin // all bytes already sent
                            state   <= ST_PREPAIRING_STOP;
                            ack     <= 1'b1;
                        end
                    end else begin  // not acked
                        read_pointer <= read_pointer + count + 1;
                        state       <= ST_PREPAIRING_STOP;
                        ack         <= 1'b0;
                    end
                end
            end

            ST_PREPAIRING_STOP:
            begin
                if( scl_negedge ) begin
                    sda_out         <= 1'b0;
                    state           <= ST_ASSERTING_STOP;
                end
            end

            ST_ASSERTING_STOP:
            begin
                if( scl_posedge ) begin
                    sda_out         <= 1'b1;
                    clock_enable    <= 1'b0;
                    // state           <= ST_IDLE;
                    ended           <= 1'b1;
                    aaa             <= MAX_CLOCK_DIVISOR_COUNT-1;
                end
                if( ~clock_enable) begin
                    if( aaa>0 ) begin
                        aaa         <= aaa - 1;
                    end else begin
                        state       <= ST_IDLE;
                    end
                end
            end
        endcase
    end
end

reg [31:0] aaa;

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("waveform.vcd");
  $dumpvars (0,i2c_alt);
  #1;
end
`endif

endmodule
