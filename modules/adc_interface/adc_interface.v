/*
    ADC interface module

    This module is an interface for TI ADC1175 chip.

    ADC1175 timing diagrams and other data in:
                        http://www.ti.com/lit/ds/symlink/adc1175.pdf

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name            Modified by     Comment
                2017/07/22      0.1             saturday        IP              Starting development
                2017/07/22      0.1             saturday        IP              Ended module and testing.
                                                                                This module decimates the clock at least in a factor of 2.

    ToDo:
                Date            Suggested by    Priority    Activity                Description
                2017/07/22      IP              High        Decimation = 1 option   Bypass clk_i to clk_o when decimation_factor=0.
                                                                                    Real decimation factor should be decimation_factor+1 with
                                                                                    this modification.
    Releases:   In development ...
*/

`timescale 1ns/1ps

module adc_interface  (
                                // Description                  Type            Width
    // Basic
    clk_i,                      // fpga clock                   input           1
    reset,                      // synch reset                  input           1

    // ADC interface
    ADC_data,                   // data                         input           DATA_WIDTH (def. 8)
    ADC_oe,                     // ouput enable, active low     output          1
    clk_o,                      // ADC clock                    output          1

    // Simple interface
    SI_data,                    // data                         output          DATA_WIDTH (def. 8)
    SI_rdy,                     // ready                        output          1
    SI_ack,                     // acknowledgment               input           1

    // Configuration
    decimation_factor,          // frec_clk_i/frec_clock_o-2    input           DF_WIDTH (def. 32)
                                // actual decimation_factor is decimation_factor+2 !!!!
                                // example: decimation_factor=0 then frec_clk_o/2=frec_clk_i

    // Error detection
    err,                        //                              output          1
                                // if after reset some data hasn't been acknowledge, then err=1.
                                // Data will be sent no matter if previous data has been acknowledge or not.
);
    // Parameters
    parameter DATA_WIDTH = 8;   // TI ADC1175 data width
    parameter DF_WIDTH   = 32;  // Decimation up to 4294967296 factor

    // Local Parameters
    //local parameter COUNT_ZERO = { DF_WIDTH {1'b0} };  //reset value of decimation counter

    // Basic
    input clk_i;
    input reset;

    // ADC interface
    input [DATA_WIDTH-1:0] ADC_data;
    output ADC_oe;
    output reg clk_o;

    // Simple interface
    output reg [DATA_WIDTH-1:0] SI_data;
    output reg SI_rdy;
    input SI_ack;

    // Configuration
    input [DF_WIDTH-1:0] decimation_factor;

    // Error detection
    output reg err;

    // Decimation counter. Counts up to decimation_factor-1.
    reg [DF_WIDTH-1:0]  counter;

    //ADC_oe <= 0;
    assign ADC_oe = 0;

    always @(posedge clk_i) begin
        if (reset == 1'b1) begin
            err = 1'b0;
            counter = 0;
            SI_rdy = 1'b0;
            clk_o = 1'b0;
        end else begin
            if ( counter == decimation_factor ) begin
                clk_o = clk_o ^ 1'b1;
                counter = 0;
            end else begin
                counter = counter + 1;
            end
            if ( SI_rdy == 1'b1 && SI_ack == 1'b1 ) begin
                SI_rdy = 1'b0;
            end
        end
    end

    always @(posedge clk_o) begin
        SI_data <= ADC_data;
        if ( SI_rdy == 1'b1 && SI_ack != 1'b0 ) begin
            err = 1'b1;
        end
        SI_rdy = 1'b1;
    end


    `ifdef COCOTB_SIM
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,adc_interface);
            #1;
        end
    `endif

endmodule
