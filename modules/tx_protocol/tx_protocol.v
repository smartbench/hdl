/*
    Tx protocol module.
    This module sends sampled data, or internal status (trigger, etc).
    Computer is master in this communication, data is sended from the FPGA responding to computer's requestes.
    Priority:
            - Send internal status.
            - Send sampled data.
            - status bits ??
    Frames start with a heather, indicating if the data sended is status, registes, samples.
    Frames are fixed length, defined by FRAME_LENGTH parameter.

    Authors:
                AD      Andres Demski
                AK      Ariel Kukulanski
                IP      Ivan Paunovic
                NC      Nahuel Carducci
    Version:
                Date           Modified by         Comment
                2017/07/31     IP                  Module created. Only IO signals writen. Behavioural haven't been done.
*/

module tx_protocol #(
    parameter FRAME_LENGTH = 20,
    parameter TX_WIDTH = 8,
    parameter ADC_WIDTH = 8
) (
    // Checks if status, registers, data was requested.
    input request_register,

    // Sampled data buffer interface (interface with circular buffer)
    input buffer_rdy,                   // Valid data indication
    input [ADC_WIDTH-1:0] buffer_data,  // Data
    output buffer_reading,              // Set this bit when buffer is requested.
    output buffer_ack,                  // Current data has been read. Requesting next sample.

    // Buffer status (interface with buffer controller)
    input buffer_full,                  // Buffer rdy can be used instead ??
    output buffer_reading_ended,        // falling edge of buffer_reading could be used instead.

    //
    input shift_reg_out,                // Registers data
    input shift_reg_empty,              // No more data to read
    output shift_reg_ack                // Data has been read

);

/* Header format:
    xxxxxxyy
    y:  00, Header only (+status ??)
        01, sending registers.
        10, sendig data.
        11, future feature.
    xxxxxx: status bits indication (trigger, etc)
    */
    parameter request_status_bit;

endmodule
