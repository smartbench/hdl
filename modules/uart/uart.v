//-----------------------------------------------------
// Design Name      : uart
// File Name        : uart.v
// Function         : Simple UART
// Original Coder   : Deepak Kumar Tala
// Modified by      : Smartbench Team
//
//
//-----------------------------------------------------

// clock in = 100MHz
// baudrate = 9600
// parameter rx_div = 651; // 100e6/(9600*16) = 651

`timescale 1ns/1ps

module uart #(
    parameter CLOCK = 99000000,
    parameter BAUDRATE = 9600
)(
    input       clk,
    input       rst,  // async

    // tx simple interface
    input [7:0] tx_data,
    input       tx_rdy,    //input ld_tx_data,
    output      tx_ack,

    // rx simple interface
    output reg [7:0] rx_data=0,
    output      rx_rdy,
    input       rx_ack, // uld_rx_data,

    // enables
    input       tx_enable,
    input       rx_enable,

    // Hardware
    input       rx,
    output reg  tx,

    // optional
    output reg  rx_over_run,
    output reg  rx_frame_err

);

    // Internal Variables
    reg [7:0]    tx_reg         ;
    reg          tx_empty       ;
    reg          tx_over_run    ;
    reg [3:0]    tx_cnt         ;
    reg [7:0]    rx_reg         ;
    reg [3:0]    rx_sample_cnt  ;
    reg [3:0]    rx_cnt         ;
    reg          rx_empty       ;
    reg          rx_d1          ;
    reg          rx_d2          ;
    reg          rx_busy        ;

    assign tx_ack = tx_empty & tx_rdy;
    assign rx_rdy = ~rx_empty;

    // UART RX Logic
    always @ (posedge clk)
    if (rst) begin
        rx_reg        <= 0;
        rx_data       <= 0;
        rx_sample_cnt <= 0;
        rx_cnt        <= 0;
        rx_frame_err  <= 0;
        rx_over_run   <= 0;
        rx_empty      <= 1;
        rx_d1         <= 1;
        rx_d2         <= 1;
        rx_busy       <= 0;
    end else begin
        // Uload the rx data
        if (rx_ack) rx_empty <= 1;
        if(rx_signal) begin
            // Synchronize the asynch signal
            rx_d1 <= rx;
            rx_d2 <= rx_d1;
            // Receive data only when rx is enabled
            if (rx_enable) begin
                // Check if just received start of frame
                if (!rx_busy && !rx_d2) begin
                    rx_busy       <= 1;   // indicates that it's receiving a frame
                    rx_sample_cnt <= 1;   // counter of samples (Fsampling=16*Fuart)
                    rx_cnt        <= 0;   // counter of bits of data.
                end
                // Start of frame detected, Proceed with rest of data
                if (rx_busy) begin
                    rx_sample_cnt <= rx_sample_cnt + 1;
                    // Logic to sample at middle of data
                    if (rx_sample_cnt == 7) begin
                        if ((rx_d2 == 1) && (rx_cnt == 0)) begin
                            // nope, wrong detection. Then, busy=0
                            rx_busy <= 0;
                        end else begin
                            rx_cnt <= rx_cnt + 1;
                            // Start storing the rx data
                            if (rx_cnt > 0 && rx_cnt < 9) begin
                                rx_reg[rx_cnt - 1] <= rx_d2;
                            end
                            if (rx_cnt == 9) begin
                                rx_busy <= 0;
                                // Check if End of frame received correctly
                                if (rx_d2 == 0) begin
                                    rx_frame_err <= 1;
                                end else begin
                                    rx_empty     <= 0;
                                    rx_frame_err <= 0;
                                    rx_data  <= rx_reg;
                                    // Check if last rx data was not unloaded,
                                    rx_over_run  <= (rx_empty) ? 0 : 1;
                                end
                            end
                        end
                    end
                end
            end else begin
                rx_busy <= 0;
            end
        end
    end

    // UART TX Logic
    always @ (posedge clk) begin
        if (rst) begin
            tx_reg        <= 0;
            tx_empty      <= 1;
            tx_over_run   <= 0;
            tx            <= 1;
            tx_cnt        <= 0;
        end else begin
            if (tx_rdy && tx_empty) begin
                tx_reg <= tx_data;
                tx_empty <= 0;
            end
            if (!tx_enable) begin
                tx_cnt <= 0;
            end else begin
                if(tx_signal) begin
                    if (tx_enable && !tx_empty) begin
                        tx_cnt <= tx_cnt + 1;
                        if (tx_cnt == 0) begin
                            tx <= 0;
                        end
                        if (tx_cnt > 0 && tx_cnt < 9) begin
                            tx <= tx_reg[tx_cnt -1];
                        end
                        if (tx_cnt == 9) begin
                            tx <= 1;
                        end
                        if (tx_cnt == 10) begin
                            tx_cnt <= 0;
                            tx_empty <= 1;
                        end
                    end
                end
            end
        end
    end

    // counters as pseudo-clocks at uart speed
    reg rx_signal=0;
    parameter [31:0] RX_DIVISOR = $rtoi($ceil($itor(CLOCK)/BAUDRATE/16)); // 100e6/(9600*16) = 651
    reg [31:0] rx_div_counter = 0;  // todo: dinamic size
    always @(posedge clk) begin
        rx_signal <= 0;
        rx_div_counter = rx_div_counter + 1;
        if(rx_div_counter == RX_DIVISOR) begin
            rx_div_counter <= 0;
            rx_signal <= 1;
        end
    end

    reg tx_signal = 0;
    parameter [31:0] TX_DIVISOR = $rtoi($ceil($itor(CLOCK)/BAUDRATE)); // 100e6/(9600*16) = 651
    reg [31:0] tx_div_counter = 0;  // todo: dinamic size
    always @(posedge clk) begin
        tx_signal <= 0;
        tx_div_counter = tx_div_counter + 1;
        if(tx_div_counter == TX_DIVISOR) begin
            tx_div_counter <= 0;
            tx_signal <= 1;
        end
    end

    initial begin
        //$display("CLOCK_PERIOD_NS:: CLOCK_PERIOD_NS=%s", CLOCK_PERIOD_NS);
        $display("RX_DIVISOR = %d", RX_DIVISOR);
        $display("TX_DIVISOR = %d", TX_DIVISOR);
        //$display("rx_div = %d", CNT_WAIT_RX);
        //$display("CNT_INACTIVE_RX:: CNT_INACTIVE_RX=%d", CNT_INACTIVE_RX);
    end

    `ifdef COCOTB_SIM   // COCOTB macro
        initial begin
            $dumpfile ("waveform.vcd");
            $dumpvars (0,uart);
            #1;
        end
    `endif

endmodule
