
/*
    Registers RX Block (communication, not instantiation of regs)

    Instances of:
        - configuration_registers_rx
        - requests_handler

*/
/*`define __REG_ADDR_WIDTH 8
`define __REG_DATA_WIDTH 16
`define __START_IDX 0
`define __STOP_IDX 1
`define __RQST_CH1_IDX 2
`define __RQST_CH2_IDX 3
`define __RQST_TRIG_IDX 4
*/

`timescale 1ns/1ps

`include "conf_regs_defines.v"

module registers_rx_block  #(
    parameter RX_DATA_WIDTH = 8,
    parameter REG_ADDR_WIDTH = 8,
    parameter REG_DATA_WIDTH = 16,
    parameter ADDR_REQUESTS = 0,
    parameter DEFAULT_REQUESTS = 0
) (
    // Basic
    input clk,                  // fpga clock
    input rst,                  // synch reset

    // Simple interface rx data
    input [RX_DATA_WIDTH-1:0] rx_data,              // data
    input rx_rdy,                                   // ready
    output rx_ack,                                  // acknowledgment

    // simple interface registers bus
    output [REG_ADDR_WIDTH-1:0] register_addr,
    output [REG_DATA_WIDTH-1:0] register_data,
    output register_rdy,

    // Output signals
    output start_o,
    output stop_o,
    output rqst_ch1,
    output rqst_ch2,
    output rqst_trigger_status_o,
    output reset_o
);

    configuration_registers_rx #(
        .RX_DATA_WIDTH(RX_DATA_WIDTH),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .REG_DATA_WIDTH(REG_DATA_WIDTH)
    ) conf_reg_rx_u (
        .clk(clk),
        .rst(rst),
        .rx_data(rx_data),
        .rx_rdy(rx_rdy),
        .rx_ack(rx_ack),
        .register_data(register_data),
        .register_addr(register_addr),
        .register_rdy(register_rdy)
    );

    requests_handler  #(
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .REG_DATA_WIDTH(REG_DATA_WIDTH),
        .MY_ADDR(ADDR_REQUESTS),
        .MY_RESET_VALUE(DEFAULT_REQUESTS)
    ) requests_handler_u (
        .clk(clk),
        .rst(rst),
        .si_addr(register_addr),
        .si_data(register_data),
        .si_rdy(register_rdy),
        .start_o(start_o),
        .stop_o(stop_o),
        .rqst_ch1(rqst_ch1),
        .rqst_ch2(rqst_ch2),
        .rqst_trigger_status_o(rqst_trigger_status_o),
        .reset_o(reset_o)
    );

    `ifdef COCOTB_SIM     // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,registers_rx_block);
            #1;
        end
    `endif

endmodule
