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

module adc_interface  #(
    parameter DATA_WIDTH = 8,//`__BITS_ADC,     // TI ADC1175 data width
    parameter CLK_DIV_WIDTH   = 32               // Decimation up to 4294967296 factor
)(
    // Basic
    input clk_i,                // fpga clock
    input rst,                  // synch reset

    // ADC interface
    input [DATA_WIDTH-1:0] ADC_data,    // data
    output ADC_oe,                      // ouput enable, active low
    output reg clk_o,                   // ADC clock

    // Simple interface
    output reg [DATA_WIDTH-1:0] SI_data = 0,    // data
    output reg SI_rdy = 1'b0,                   // ready
    input SI_ack,                               // acknowledge

    // Configuration
    input [CLK_DIV_WIDTH-1:0] decimation_factor  // frec_clk_i/frec_clock_o-1
                                // actual decimation_factor is decimation_factor+1 !!!!
                                // example: decimation_factor=0 then frec_clk_o=frec_clk_i

);

    // Local Parameters
    //local parameter COUNT_ZERO = { CLK_DIV_WIDTH {1'b0} };  //reset value of decimation counter

    // Decimation counter. Counts up to decimation_factor-1.
    reg [CLK_DIV_WIDTH-1:0]  counter;

    // Divided clock. If decimation_factor!=0 then clk_o is assigned to clk_o_divided
    reg clk_o_divided;

    //ADC_oe is always 0
    assign ADC_oe = 0;


    always @( decimation_factor or clk_i or clk_o_divided ) begin           // Mux selecting between clk_i and clk_o_divided
        if ( decimation_factor == 0 ) begin
            clk_o = clk_i;
        end else begin
            clk_o = clk_o_divided;
        end
    end

    always @(posedge clk_i) begin
        if (rst == 1'b1) begin                                            // RESET
            counter <= 0;
            SI_rdy <= 1'b0;
            clk_o_divided <= 1'b0;
        end else begin
            if ( decimation_factor != 0 ) begin                                         // Clock division
                if ( counter == (decimation_factor-1 ) ) begin
                    clk_o_divided <= ~clk_o_divided;
                    counter <= 0;
                end else begin
                    counter <= counter + 1;
                end
            end

            if ( SI_rdy == 1'b1 && SI_ack == 1'b1 && decimation_factor != 0 ) begin     // Checking if last data was acknowledge
                SI_rdy <= 1'b0;
            end

            // checking posedge(clk_o), without using clk_o as a clk resource.
            if ( ( counter == (decimation_factor-1) && clk_o_divided == 0 ) || decimation_factor == 0 ) begin
                if( SI_rdy == 1'b0 || ( SI_rdy == 1'b1 && SI_ack == 1'b1 ) ) begin
                //if we were not sending or last data sended has been acknowledged
                    SI_data <= ADC_data; //send new data
                    SI_rdy <= 1'b1;
                end
            end
        end
    end


    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,adc_interface);
            #1;
        end
    `endif

endmodule
