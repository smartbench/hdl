/*
    This file have macros for address, intial values, number of registers and register width.
    Parameters are updated from this definition. DO NOT change it in other files or in instantiation (only do that for testing).

    REGS/REGISTERS/.. refers to normal registers.
    REQUEST_REGS/TRIGGER_REGS/... refers to registers that are erased after acknowledge the data reading.
    REGS_TOTAL/.. reefers to both.
*/


`ifndef __CONF_REGS_DEFINES_V
`define __CONF_REGS_DEFINES_V


`define __ADC_DF_WIDTH  32
`define __RAM_SIZE_CH   (4096*4)          // RAM for each channel
`define __MA_ACUM_WIDTH 12

/*******************************************************************************
                            HARDWARE DEFINITIONS
*******************************************************************************/
`define __BITS_ADC      8
`define __BITS_DAC      10

/*******************************************************************************
                            BASIC REGISTER DEFINITIONS
*******************************************************************************/

`define __FT245_DATA_WIDTH          8
`define __RX_WIDTH                  8       // Register and address width are a multiple of __RX_WIDTH
`define __TX_WIDTH                  8       //
`define __NUM_REGS                  10
`define __NUM_REQUEST_REGS          1
`define __NUM_REGS_TOTAL            ( `__NUM_REGS + `__NUM_REQUEST_REGS )
`define __REG_DATA_WIDTH            16                                          // Register width
`define __REG_ADDR_WIDTH_MIN        ( $clog2( `__NUM_REGS_TOTAL ) )
//__ADDR_WIDTH_MIN rounded to next multiple of a byte
`define __REG_ADDR_WIDTH            ( $rtoi( $ceil( $itor(`__REG_ADDR_WIDTH_MIN) / `__RX_WIDTH ) ) * 8 )
`define __REGS_STARTING_ADDR        1                                           // First reg addr after request regs.


/*******************************************************************************
                                ADDRESSES
*******************************************************************************/

// Request regs addresses
`define __ADDR_REQUESTS                 0

// Conf regs addresses
`define __ADDR_SETTINGS_CHA             1
`define __ADDR_SETTINGS_CHB             2
`define __ADDR_DAC_CHA                  3
`define __ADDR_DAC_CHB                  4
`define __ADDR_TRIGGER_SETTINGS         5
`define __ADDR_TRIGGER_VALUE            6
`define __ADDR_NUM_SAMPLES              7
`define __ADDR_PRETRIGGER               8
`define __ADDR_ADC_CLK_DIV_CHA_L        9
`define __ADDR_ADC_CLK_DIV_CHA_H        10
`define __ADDR_ADC_CLK_DIV_CHB_L        11
`define __ADDR_ADC_CLK_DIV_CHB_H        12
`define __ADDR_N_MOVING_AVERAGE_CHA     13
`define __ADDR_N_MOVING_AVERAGE_CHB     14

/*******************************************************************************
                                BIT FIELDS
*******************************************************************************/

// CONF_CHA, CONF_CHB
`define __CONF_CH_ATT                       7:5
`define __CONF_CH_GAIN                      4:2
`define __CONF_CH_DC_COUPLING               1:1
`define __CONF_CH_ON                        0:0

// trigger_conf
//`define __TRIGGER_CONF_MODE               3:3
`define __TRIGGER_CONF_SOURCE_SEL           1:0
`define __TRIGGER_CONF_EDGE                 0

// Requests handler
`define __RQST_START_IDX        0
`define __RQST_STOP_IDX         1
`define __RQST_CHA_IDX          2
`define __RQST_CHB_IDX          3
`define __RQST_TRIG_IDX         4
`define __RQST_RST_IDX          5

/*******************************************************************************
                        INITIAL VALUES OF REGESTERS
*******************************************************************************/

`define __IV_CONF_CHA               16'b11100001
`define __IV_CONF_CHB               16'b11100001
`define __IV_DAC_CHA                (1 << (`__BITS_DAC-1)) // 16'b1000000000000000
`define __IV_DAC_CHB                (1 << (`__BITS_DAC-1)) // 16'b1000000000000000
`define __IV_TRIGGER_SETTINGS       16'b0
`define __IV_TRIGGER_VALUE          (1 << (`__BITS_ADC-1)) // 16'b10000000
`define __IV_NUM_SAMPLES            16'b10000000
`define __IV_PRETRIGGER             16'b0
`define __IV_ADC_CLK_DIV_CHA_H      16'd0
`define __IV_ADC_CLK_DIV_CHA_L      16'd4
`define __IV_ADC_CLK_DIV_CHB_H      16'd0
`define __IV_ADC_CLK_DIV_CHB_L      16'd4
`define __IV_AVERAGE_N              16'b1
`define __IV_N_MOVING_AVERAGE_CHA   16'b0
`define __IV_N_MOVING_AVERAGE_CHB   16'b0

`endif
