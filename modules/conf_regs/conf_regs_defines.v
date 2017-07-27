/*
    This file have macros for address, intial values, number of registers and register width.
    Parameters are updated from this definition. DO NOT change it in other files or in instantiation (only do that for testing).

    REGS/REGISTERS/.. refers to normal registers.
    REQUEST_REGS/TRIGGER_REGS/... refers to registers that are erased after acknowledge the data reading.
    REGS_TOTAL/.. reefers to both.
*/

`ifndef __CONF_REGS_DEFINES__V
`define __CONF_REGS_DEFINES__V

/*******************************************************************************
                            BASIC REGISTER DEFINITIONS
*******************************************************************************/

`define __RX_WIDTH                  8                                           // Register and address width are a multiple of __RX_WIDTH
`define __TX_WIDTH                  8                                           // Shift register out width
`define __NUM_REGS                  10
`define __NUM_REQUEST_REGS          1
`define __NUM_REGS_TOTAL            ( `__NUM_REGS + `__NUM_REQUEST_REGS )
`define __DATA_WIDTH                16                                          // Register width
`define __ADDR_WIDTH_MIN            ( $clog2( `__NUM_REGS_TOTAL ) )
//__ADDR_WIDTH_MIN rounded to next multiple of a byte
`define __ADDR_WIDTH                ( $rtoi( $ceil( $itor(`__ADDR_WIDTH_MIN) / `__RX_WIDTH ) ) * 8 )
`define __REGS_STARTING_ADDR        1                                           // First reg addr after request regs.

/*******************************************************************************
                                ADDRESSES
*******************************************************************************/

// Request regs addresses
`define __ADDR_REQUESTS             0

// Conf regs addresses
`define __ADDR_CONF_CH1             1
`define __ADDR_CONF_CH2             2
`define __ADDR_DAC_CH1              3
`define __ADDR_DAC_CH2              4
`define __ADDR_TRIGGER_CONF         5
`define __ADDR_TRIGGER_VALUE        6
`define __ADDR_NUM_SAMPLES          7
`define __ADDR_PRE_TRIGGER          8
`define __ADDR_DECIMATION_L         9
`define __ADDR_DECIMATION_H         10

/*******************************************************************************
                                BIT FIELDS
*******************************************************************************/

// CONF_CH1, CONF_CH2
`define __CONF_CH_ATT                       7:5
`define __CONF_CH_GAIN                      4:2
`define __CONF_CH_DC_COUPLING               1:1
`define __CONF_CH_ON                        0:0

// trigger_conf
`define __TRIGGER_CONF_MODE                 3:3
`define __TRIGGER_CONF_EDGE                 2:2
`define __TRIGGER_CONF_SOURCE_SEL           1:0

/*******************************************************************************
                        INITIAL VALUES OF REGESTERS
*******************************************************************************/

`define __IV_CONF_CH1               16'b11100001
`define __IV_CONF_CH2               16'b11100000
`define __IV_DAC_CH1                16'b1000000000000000
`define __IV_DAC_CH2                16'b1000000000000000
`define __IV_TRIGGER_CONF           16'b0
`define __IV_TRIGGER_VALUE          16'b10000000
`define __IV_NUM_SAMPLES            16'b10000000
`define __IV_PRE_TRIGGER            16'b0
`define __IV_DECIMATION_L           16'b0
`define __IV_DECIMATION_H           16'b0

`define __IV_ARRAY  {                            \
                        `__IV_CONF_CH1,          \
                        `__IV_CONF_CH2,          \
                        `__IV_DAC_CH1,           \
                        `__IV_DAC_CH2,           \
                        `__IV_TRIGGER_CONF,      \
                        `__IV_TRIGGER_VALUE,     \
                        `__IV_NUM_SAMPLES,       \
                        `__IV_PRE_TRIGGER,       \
                        `__IV_DECIMATION_L,      \
                        `__IV_DECIMATION_H       \
                    }

`endif // __CONF_REGS_DEFINES__V
