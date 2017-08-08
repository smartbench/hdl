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
                07/08/17        NC              Medium                              Generic desciption of register assigment. Look for NOTE comment

    Releases:   To be tested
*/

// `include "moving_average/moving_average.v"
// `include "adc_interface/adc_interface.v"
// `include "moving_average.v"
// `include "adc_interface.v"


`timescale 1ns/1ps

module adc_top #(
    parameter ADC_DATA_WIDTH = 8,
    parameter ADC_DF_WIDTH   = 32,  // ADC decimation
    parameter MA_ACUM_WIDTH = 12,     // Moving Average Acumulator
    parameter SI_DATA_WIDTH = 16,    // Single Interface
    parameter SI_ADDR_WIDTH = 8,
    parameter ADC_DF_DV_REG = 0,
    parameter MA_K_FACTOR_DV_REG = 3,
    parameter REG_ADC_DF_ADDR_L = 0,
    parameter REG_ADC_DF_ADDR_H = 1,
    parameter REG_MA_DF_ADDR = 2
    // parameter REG_ADC_DF_WIDTH = 32,
    // parameter REG_MA_K_FACTOR_WIDTH = 4
  )(
    // Basic
    input clk_i,
    input reset,

    // ADC interface (to the ADC outside of the FPGA)
    input [ADC_DATA_WIDTH-1:0] adc_data,
    output adc_oe,
    output wire clk_o,

    // ADC Simple Interface (inside of the FPGA)
    output wire [ADC_DATA_WIDTH-1:0] adc_si_data,
    output wire adc_si_rdy,
    // input adc_si_ack,

    // Registers Simple Interface
    input [SI_DATA_WIDTH-1:0] reg_si_data,
    input [SI_ADDR_WIDTH-1:0] reg_si_addr,
    input reg_si_rdy,
    output reg reg_si_ack = 0
    );

    wire [ADC_DATA_WIDTH-1:0] adc_si_data_temp;
    wire adc_si_rdy_temp;
    reg adc_si_ack_temp = 1'b1;
    reg [ADC_DF_WIDTH-1:0] adc_df                       = ADC_DF_DV_REG;  // adc decimation factor DefaultValue  register
    reg [$clog2(MA_ACUM_WIDTH-ADC_DATA_WIDTH)-1:0] ma_k = MA_K_FACTOR_DV_REG; // moving average k factor DefaultValue register

    adc_interface #(
      .DATA_WIDTH         (ADC_DATA_WIDTH),
      .DF_WIDTH           (ADC_DF_WIDTH)
    )adc_interface_inst(
      .clk_i              (clk_i),
      .reset              (reset),
      .ADC_data           (adc_data),
      .ADC_oe             (adc_oe),
      .clk_o              (clk_o),
      .SI_data            (adc_si_data_temp),
      .SI_rdy             (adc_si_rdy_temp),
      .SI_ack             (adc_si_ack_temp),
      .decimation_factor  (adc_df)
      );

    moving_average #(
      .BITS_ADC           (ADC_DATA_WIDTH),
      .BITS_ACUM          (MA_ACUM_WIDTH)
    )moving_average_inst(
      .clk                (clk_i),
      .rst                (reset),
      .k                  (ma_k),
      .sample_in          (adc_si_data_temp),
      .rdy_in             (adc_si_rdy_temp),
      .sample_out         (adc_si_data),
      .rdy_out            (adc_si_rdy)
      );


    always @ ( posedge(clk_i) ) begin
      if (reset == 1'b1) begin
        adc_df <= ADC_DF_DV_REG;
        ma_k <= MA_K_FACTOR_DV_REG;
        reg_si_ack <=0;
      end else begin
        if (reg_si_rdy==1'b1) begin
          case (reg_si_addr)
            // NOTE: not generic Description!! If ADC_DF_WIDTH or SI_DATA_WIDTH changes
            // gotta check the lines below
            REG_ADC_DF_ADDR_L: begin
              adc_df[SI_DATA_WIDTH-1:0] <= reg_si_data;
              reg_si_ack <= 1;
              end
            REG_ADC_DF_ADDR_H: begin
              adc_df[ADC_DF_WIDTH-1:SI_DATA_WIDTH] <= reg_si_data;
              reg_si_ack <= 1;
              end
            REG_MA_DF_ADDR:  begin
              ma_k <= reg_si_data[$clog2(MA_ACUM_WIDTH-ADC_DATA_WIDTH)-1:0];
              reg_si_ack <= 1;
              end
            default:       begin     ;
              reg_si_ack <= 0;
              end
          endcase
        end else begin
          reg_si_ack <= 0;
        end
      end
    end

    `ifdef COCOTB_SIM                                                        // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,adc_top);
            #1;
        end
    `endif

endmodule // adc_top
