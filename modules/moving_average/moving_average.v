

/*
    Averaging Module

    This module makes a moving average filter with decimation.

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name                Modified by         Comment
                2017/07/27      0.1             first_approach      AK                  Starting development...


    ToDo:
                Date            Suggested by    Priority    Activity                Description

    Releases:   In development ...
*/

`include "conf_regs_defines.v"

`timescale 1ns/1ps

module moving_average  #(
    parameter BITS_ADC = 8,
    parameter BITS_ACUM = 12
) (
                                    // Description              Type            Width
    // Basic
    input clk,                      // fpga clock               input           1
    input rst,                      // synch reset              input           1

    // Config. Parameters
    input [$clog2(BITS_ACUM-BITS_ADC)-1:0] k,   // k=log2(decimation_factor)

    // Input samples
    input [BITS_ADC-1:0] sample_in,     // input value              input           BITS_ADC (def. 8)
    input rdy_in,

    // Output samples
    output reg [BITS_ADC-1:0] sample_out = 0,
    output reg rdy_out = 0

);

    // To avoid overflow in the acum, with a decimation factor DF,
    //  it should be able to store DF*MAX_VAL_ADC, so it's size has
    //  to be log2(K)+log2(MAX_VAL_ADC) = log2(DF) + BITS_ADC.
    // DF has to be a power of two, so to reduce the number of innecesary
    //  wires, the input parameter is k=log2(DF) instead of just DF.
    // Then, DF = 2^k = (1 << k)

    // The maximum decimation factor with an accumulator depends on the
    //  size of the accumulator and adc, and is:
    //      MAX_DECIM_FACTOR = 1 << (BITS_ACUM-BITS_ADC);
    localparam BIT_DIFF = BITS_ACUM - BITS_ADC;

    wire [BIT_DIFF-1:0] DF;
    wire [BITS_ACUM-1:0] sum_tmp;

    reg [BIT_DIFF-1:0] count = 1;
    reg [BITS_ACUM-1:0] acum = 0;

    // Decimation Factor = 2^k = 1 << k
    assign DF = (1 << k);

    // sum_tmp = acum + new_sample
    assign sum_tmp[BITS_ACUM-1:0] = acum + {{BIT_DIFF{1'b0}} , sample_in};


    // Carga DF en el contador y luego se resta. Mejor para cuando se cambia
    //  DF sobre la marcha, porque la comparación es contra una cte.
    always @( posedge(clk) ) begin
        rdy_out <= 1'b0;
        sample_out <= 0;
        if ( rst == 1'b1 ) begin
            acum <= 0;
            count <= DF; // Starts from DF
        end else begin
            if(rdy_in == 1'b1) begin
                if( count != 1 ) begin
                    count <= count - 1;
                    acum <= sum_tmp;
                end else begin
                    acum <= 0;
                    //sample_out <= sum_tmp[BITS_ACUM-1:BIT_DIFF];
                    sample_out <= (sum_tmp >> k);
                    rdy_out <= 1'b1;
                    count <= DF;
                end
            end
        end
    end

    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,moving_average);
            #1;
        end
    `endif

endmodule
