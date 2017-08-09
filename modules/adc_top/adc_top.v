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

/*
`ifndef COCOTB_SIM                // COCOTB macro
  `include "../moving_average/moving_average.v"
  `include "../adc_interface/adc_interface.v"
`endif*/



`timescale 1ns/1ps

module adc_top #(
    parameter BITS_ADC = 8,//`__BITS_ADC,
    parameter ADC_DF_WIDTH   = 32,      // ADC decimation
    parameter MA_ACUM_WIDTH = 12,       // Moving Average Acumulator
    parameter REG_DATA_WIDTH = 16,//`REG_DATA_WIDTH,    // Simgle Interface
    parameter REG_ADDR_WIDTH = 8,//`REG_ADDR_WIDTH,
    parameter ADC_DF_DV_REG = 0,
    parameter MA_K_FACTOR_DV_REG = 3,
    parameter REG_ADDR_ADC_DF_L = 0,
    parameter REG_ADDR_ADC_DF_H = 1,
    parameter REG_ADDR_MOV_AVE_K = 2
  )(
    // Basic
    input clk_i,
    input rst,

    // ADC interface (to the ADC outside of the FPGA)
    input [BITS_ADC-1:0] adc_data_i,
    output adc_oe,
    output clk_o,

    // ADC Simple Interface (inside of the FPGA)
    output [BITS_ADC-1:0] si_data_o,
    output si_rdy_o,

    // Registers Simple Interface
    input [REG_DATA_WIDTH-1:0] reg_si_data,
    input [REG_ADDR_WIDTH-1:0] reg_si_addr,
    input reg_si_rdy
    );

    wire [BITS_ADC-1:0] adc_interface_si_data;
    wire adc_interface_si_rdy;
    wire adc_interface_si_ack;
    reg [ADC_DF_WIDTH-1:0] adc_df                       = ADC_DF_DV_REG;  // adc decimation factor DefaultValue  register
    reg [$clog2(MA_ACUM_WIDTH-BITS_ADC)-1:0] ma_k = MA_K_FACTOR_DV_REG; // moving average k factor DefaultValue register
    
    reg rst_restart = 1'b0;
    assign adc_interface_si_ack = adc_interface_si_rdy;

    adc_interface #(
      .DATA_WIDTH         (BITS_ADC),
      .DF_WIDTH           (ADC_DF_WIDTH)
    )adc_interface_inst(
      .clk_i              (clk_i),
      .rst                  (rst_restart),
      .ADC_data           (adc_data_i),
      .ADC_oe             (adc_oe),
      .clk_o              (clk_o),
      .SI_data            (adc_interface_si_data),
      .SI_rdy             (adc_interface_si_rdy),
      .SI_ack             (adc_interface_si_ack),
      .decimation_factor  (adc_df)
      );

    moving_average #(
      .BITS_ADC           (BITS_ADC),
      .BITS_ACUM          (MA_ACUM_WIDTH)
    )moving_average_inst(
      .clk                (clk_i),
      .rst                (rst_restart),
      .k                  (ma_k),
      .sample_in          (adc_interface_si_data),
      .rdy_in             (adc_interface_si_rdy),
      .sample_out         (si_data_o),
      .rdy_out            (si_rdy_o)
      );

    
    // Registers
    always @ ( posedge(clk_i) ) begin
      rst_restart <= 1'b0;
      if (rst == 1'b1) begin
        adc_df <= ADC_DF_DV_REG;
        ma_k <= MA_K_FACTOR_DV_REG;
        rst_restart <= 1'b1;
      end else begin
        if (reg_si_rdy==1'b1) begin

          case (reg_si_addr)
            // NOTE: not generic Description!! If ADC_DF_WIDTH or REG_DATA_WIDTH changes
            // gotta check the lines below
            // NOTE ANSWER: added a 1 clock duration reset for each time something changes
            REG_ADDR_ADC_DF_L:
            begin
              adc_df[REG_DATA_WIDTH-1:0] <= reg_si_data;
              rst_restart <= 1'b1;
            end
            REG_ADDR_ADC_DF_H:
            begin
              adc_df[ADC_DF_WIDTH-1:REG_DATA_WIDTH] <= reg_si_data;
              rst_restart <= 1'b1;
            end
              
            REG_ADDR_MOV_AVE_K:
            begin
              ma_k <= reg_si_data[$clog2(MA_ACUM_WIDTH-BITS_ADC)-1:0];
              rst_restart <= 1'b1;
             end
            
            default:
            begin
            end
            
          endcase
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
