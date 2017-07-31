/*
A simple register indicating an event has happened.
After register has been acked, it's automatically erased.

Authors:
            AD      Andres Demski
            AK      Ariel Kukulanski
            IP      Ivan Paunovic
            NC      Nahuel Carducci
Version:
            Date           Modified by         Comment
            2017/07/31     IP                  Module created. Behavioural writen, but not tested.
*/

module status_bit #(

)(
    // Basic signals
    input clk,
    input rst,

    // IO interface
    input set,      // status change to 1 when set input is 1
    input ack,      // (reset) status change to 0 when ack is 1
    output status   // actual status
);

    always @( posedge(clk) ) begin
        if( rst == 1'b1 || ack ) begin
            status <= 0;
        end else begin
            if( set == 1) begin
                status <= 0;
            end
        end
    end
endmodule
