/*
    ADC Top

    This module instantiates adc_interface and moving_average modules.
    Also, implements an interface to connect into the Simple Interface bus for
    registers.

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci

    Version:
                Date            Number          Name                Modified by         Comment
                05/08/2017      0.1             first_approach      NC                  Starting development...


    ToDo:
                Date            Suggested by    Priority    Activity                Description

    Releases:   In development ...
*/

`timescale 1ns/1ps

module adc_top #(
    parameter ADC_DATA_WIDTH = 8,
    parameter ADC_DF_WIDTH   = 32,  // ADC decimation
    parameter MA_BITS_ACUM = 12     // Moving Average Acumulator
    parameter SI_DATA_WIDTH = 32    // Single Interface
  )(
    // Basic
    input clk_i;
    input reset;

    // ADC interface (to the ADC outside of the FPGA)
    input [DATA_WIDTH-1:0] ADC_data;
    output ADC_oe;
    output reg clk_o;

    // ADC Simple Interface (inside of the FPGA)
    output reg [DATA_WIDTH-1:0] ADC_SI_data;
    output reg ADC_SI_rdy;
    input ADC_SI_ack;

    // Registers Simple Interface
    input [SI_DATA_WIDTH-1:0] REG_SI_data;
    input [SI_ADDR_WIDTH-1:0] REG_SI_addr;
    input REG_SI_rdy;
    output REG_SI_ack;

    );

    wire adc_df; // adc decimation factor


    adc_interface #(
      .DATA_WIDTH(ADC_DATA_WIDTH),
      .DF_WIDTH(ADC_DF_WIDTH)
      )adc_interface_inst(
        .clk_i              (clk_i),
        .reset              (reset),
        .ADC_data           (ADC_data),
        .ADC_oe             (ADC_oe),
        .clk_o              (clk_o),
        .SI_data            (ADC_SI_data),
        .SI_rdy             (ADC_SI_rdy),
        .SI_ack             (ADC_SI_ack),
        .decimation_factor  (adc_df)
        );



    always @ ( posedge(clk) ) begin

      if (REG_SI_rdy==1'b1) begin
        case (REG_SI_addr)
          value: REG_ADC_ADDR;
          default: ;
        endcase


      end


    end





endmodule // adc_top
