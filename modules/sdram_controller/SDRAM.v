
// Between read and write/ write and read, one clock with rdy low is needed.
// Change FSM using write after read and read after write functionalities if this behaviour is not wanted.

module SDRAM #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 20, // Total addr width
    parameter ADDR_BUS_WIDTH = 12 // Physical bus width
)(

    input clk_i,
    input rst,

    // "PSEUDO DUAL PORT" INTERNAL INTERFACE

    input [ADDR_WIDTH-1:0] waddr,
    input [DATA_WIDTH-1:0] wdata,
        
    input we,
    
    input [ADDR_WIDTH-1:0] raddr,
    output reg [DATA_WIDTH-1:0] rdata,
    
    // Simple interface ready/ack logic
    input rdy,
    output reg ack,

    // RAM INTERFACE

    output clk_o,
    output reg clke,

    input [DATA_WIDTH-1:0] data_i,
    output reg [DATA_WIDTH-1:0] data_o,
    output reg [ADDR_BUS_WIDTH-1:0] addr,

    output reg csn,
    output reg rasn,
    output reg casn,
    output reg wen,
    
    output reg LDQM,
    output reg UDQM
);

    // rounded up division
    function cdiv;
    input n,d;
    begin
        cdiv = (n/d) + (n%d) ? 1:0;
    end
    endfunction

    localparam MODE_USED = 12'b000000100111;

    // Timing parameters
    localparam CLK_T_NS = 10;                                           // Clock period in nanoseconds
    localparam WAIT_CNT_200us = cdiv( 200000 , CLK_T_NS );              // Stable clock waiting time in reset sequence
    localparam WAIT_CNT_PRCA = cdiv( 21 , CLK_T_NS );                   // Precharge command waiting time
    localparam WAIT_CNT_LM = 1;                                         // Load mode command waiting time
    localparam WAIT_CNT_AR = cdiv( 63 , CLK_T_NS );                     // Auto refresh command waiting time
    localparam WAIT_CNT_ACTIVATE = cdiv( 42 , CLK_T_NS );               // Activate command waiting time
    localparam WAIT_CNT_REFRESH = 15625 / CLK_T_NS;                     // 4096 refresh cycles in 64ms, or 1 refresh cycle per 15625ns ( rounded down! ).
    localparam WAIT_CNT_ACTIVE_TO_PRECHARGE_MAX = 100000 / CLK_T_NS;    // Maximum time active without precharging ( rounded down! )
    localparam WAIT_CNT_WR = 1;                                         // Two clocks between last data writen and next precharge

    // Initialization state machine, states parameters and register
    localparam RST_SEQUENCE_STATE_WAITING_200us = 0;
    localparam RST_SEQUENCE_STATE_PRECHARGE_ALL = 1;
    localparam RST_SEQUENCE_STATE_PRECHARGE_ALL_WAITING = 2;
    localparam RST_SEQUENCE_STATE_LOAD_MODE = 3;
    localparam RST_SEQUENCE_STATE_LOAD_MODE_WAITING = 4;
    localparam RST_SEQUENCE_STATE_AUTOREFRESH_1 = 5;
    localparam RST_SEQUENCE_STATE_AUTOREFRESH_1_WAITING = 6;
    localparam RST_SEQUENCE_STATE_AUTOREFRESH_2 = 7;
    localparam RST_SEQUENCE_STATE_AUTOREFRESH_2_WAITING = 8;
    localparam RST_SEQUENCE_STATE_FINISHED = 9;
    localparam NUM_RST_SEQUENCE_STATES = 10;
    localparam RST_SEQUENCE_STATE_WIDTH = $clog2( NUM_RST_SEQUENCE_STATES );
    
    reg [RST_SEQUENCE_STATE_WIDTH-1:0] rst_sequence_state = 0;
    
    // Operation state machine, states parameters and register
    
    localparam STATE_IDLE = 0;
    localparam STATE_WAITING_ACTIVE = 1;
    localparam STATE_READING = 2;
    localparam STATE_WRITING = 3;
    localparam STATE_EXITING_WRITE = 4;
    localparam STATE_PRECHARGING = 5;
    
    localparam NUM_STATES = 6;
    localparam STATE_WIDTH = $clog2( NUM_STATES );
    
    reg [STATE_WIDTH-1:0] state;
    
    // After command waiting counter
    
    localparam COUNTER_WIDTH = $clog2( WAIT_CNT_200us -1);
    reg [COUNTER_WIDTH-1:0] cnt;

    // Autorefresh period counter
    localparam REFRESH_COUNTER_WIDTH = $clog2( WAIT_CNT_REFRESH-1 );
    reg [REFRESH_COUNTER_WIDTH-1:0] refresh_cnt = WAIT_CNT_AR-1;
    
    // Active to precharge counter
    localparam ATOP_COUNTER_WIDTH = $clog2( WAIT_CNT_ACTIVE_TO_PRECHARGE_MAX-1 );
    reg [ ATOP_COUNTER_WIDTH-1:0 ] atop_cnt;

    
    // Active row and bank
    reg [11:0] last_row;
    wire [11:0] row; //actual row

    // Actual column
    wire [7:0] column;
    
    // Actual bank
    wire bank;
    
    // Commands
    task INHIBIT;
    begin
        csn <= 1'b1;
    end
    endtask 

    task NOP;
    begin
        rasn <= 1'b1;
        casn <= 1'b1;
        wen <= 1'b1;
    end
    endtask

    task PRECHARGE_ALL;
    begin
        rasn <= 1'b0;
        casn <= 1'b1;
        wen <= 1'b0;
        addr[10] <= 1'b1;
    end
    endtask

    task LOAD_MODE;
    input mode;
    begin
        addr <= mode;
        rasn <= 1'b0;
        casn <= 1'b0;
        wen <= 1'b0;
    end
    endtask

    task AUTOREFRESH;
    begin
        rasn <= 1'b0;
        casn <= 1'b0;
        wen <= 1'b1;
    end
    endtask
    
    task ACTIVATE;
    begin
        rasn <= 1'b0;
        casn <= 1'b1;
        wen <= 1'b1;
        addr <= row;
    end
    endtask

    task MASK;
    begin
        LDQM <= 1'b1;
        UDQM <= 1'b1;
    end
    endtask

    task UNMASK;
    begin
        LDQM <= 1'b0;
        UDQM <= 1'b0;
    end
    endtask
    
    task WRITE;
    begin
        rasn <= 1'b1;
        casn <= 1'b0;
        wen <= 1'b0;
        addr <= column;
        addr[10] <= 1'b0;
        addr[11] <= bank;
    end
    endtask
    
    task READ;
    begin
        rasn = 1'b1;
        casn = 1'b0;
        wen = 1'b1;
        addr <= column;
        addr[10] <= 1'b0;
        addr[11] <= bank;
    end
    endtask
    
    assign clk_o = clk_i; // RAM clock generation
    
    assign row = we ? waddr[11:0] : raddr[11:0]; // Actual row
    assign column = we ? waddr[7:0] : raddr[7:0]; // Actual row
    assign bank = row[11];
    
    // COUNTERS
    always @( posedge clk_i ) begin
        if( !rst ) begin
            if( cnt ) begin
                cnt <= cnt - 1;
            end
            
            if( refresh_cnt ) begin
                refresh_cnt <= refresh_cnt - 1;
            end
            
            if( atop_cnt ) begin
                atop_cnt <= atop_cnt - 1;
            end
        end    
    end
    
    // RESET SEQUENCE
    always @( posedge clk_i ) begin
        if( rst ) begin
            rst_sequence_state <= RST_SEQUENCE_STATE_WAITING_200us;
            cnt <= WAIT_CNT_200us-1;
            csn <= 0;
            clke <= 0;
            MASK();
            NOP();
        end else begin
            case( rst_sequence_state ) 
                
                RST_SEQUENCE_STATE_WAITING_200us: 
                begin
                    if( !cnt ) begin
                        clke <= 1;
                        rst_sequence_state <= RST_SEQUENCE_STATE_PRECHARGE_ALL;
                    end
                end

                RST_SEQUENCE_STATE_PRECHARGE_ALL:
                begin
                    PRECHARGE_ALL();
                    cnt <= WAIT_CNT_PRCA-1;
                    rst_sequence_state <= RST_SEQUENCE_STATE_PRECHARGE_ALL_WAITING;
                end
                
                RST_SEQUENCE_STATE_PRECHARGE_ALL_WAITING:
                begin
                    NOP();
                    if( !cnt ) begin
                        rst_sequence_state <= RST_SEQUENCE_STATE_LOAD_MODE;
                    end
                end
                
                RST_SEQUENCE_STATE_LOAD_MODE:
                begin
                    LOAD_MODE( MODE_USED );
                    cnt <= WAIT_CNT_LM-1;
                    rst_sequence_state <= RST_SEQUENCE_STATE_LOAD_MODE_WAITING;
                end
                
                RST_SEQUENCE_STATE_LOAD_MODE_WAITING:
                begin
                    NOP();
                    if( !cnt ) begin
                        rst_sequence_state <= RST_SEQUENCE_STATE_AUTOREFRESH_1;
                    end
                end

                RST_SEQUENCE_STATE_AUTOREFRESH_1:
                begin
                    AUTOREFRESH();
                    cnt <= WAIT_CNT_AR-1;
                    rst_sequence_state <= RST_SEQUENCE_STATE_AUTOREFRESH_1_WAITING;
                end

                RST_SEQUENCE_STATE_AUTOREFRESH_1_WAITING:
                begin
                    NOP();
                    if( !cnt ) begin
                        rst_sequence_state <= RST_SEQUENCE_STATE_AUTOREFRESH_2;
                    end
                end

                RST_SEQUENCE_STATE_AUTOREFRESH_2:
                begin
                    AUTOREFRESH();
                    cnt <= WAIT_CNT_AR-1;
                    rst_sequence_state <= RST_SEQUENCE_STATE_AUTOREFRESH_2_WAITING;
                end

                RST_SEQUENCE_STATE_AUTOREFRESH_2_WAITING:
                begin
                    NOP();
                    if( !cnt ) begin
                        rst_sequence_state <= RST_SEQUENCE_STATE_FINISHED;
                    end
                end

                RST_SEQUENCE_STATE_FINISHED: begin end
                default: begin end
            endcase
        end
    end
    
    // READ/WRITE STATE MACHINE
    always @( posedge clk_i ) begin
        if( !rst & rst_sequence_state == RST_SEQUENCE_STATE_FINISHED ) begin
            
            case( state )            
                STATE_IDLE:
                begin
                    if( !refresh_cnt ) begin // REFRESH CYCLE, if a refresh is needed we return to iddle state after Autorefresh command.
                        refresh_cnt <= WAIT_CNT_REFRESH-1;
                        cnt <= WAIT_CNT_AR;
                        AUTOREFRESH();
                    end else begin
                        if( rdy && !cnt ) begin
                            state <= STATE_WAITING_ACTIVE;
                            cnt <= WAIT_CNT_ACTIVATE;
                            ACTIVATE();
                            last_row <= row;
                        end
                    end
                end
                
                STATE_WAITING_ACTIVE:
                begin
                    NOP();
                    if( !cnt ) begin
                        if( we ) begin
                            WRITE();
                            data_o <= wdata;
                            state <= STATE_WRITING;
                        end else begin
                            READ();
                            cnt <= 1; // o 1, segun clock
                            state <= STATE_READING;
                        end
                    end
                end
                                
                STATE_READING:
                begin
                    // Using read interrupted by a read.
                    // Output data has two clocks latency.
                    READ();
                    if( !refresh_cnt & !cnt & rdy & last_row == row ) begin
                        rdata <= data_i;
                        ack <= 1;
                    end                    
                    if( !rdy | last_row != row | !refresh_cnt ) begin
                        ack <= 0;
                        cnt <= WAIT_CNT_PRCA - 1;
                        PRECHARGE_ALL();
                        state <= STATE_PRECHARGING;
                    end
                end
                
                STATE_WRITING:
                begin
                    if( rdy & last_row == row & ! refresh_cnt ) begin
                        // Using write interrupted by a write.
                        WRITE();
                        data_o <= wdata;
                        ack <= 1;
                    end else begin
                        ack <= 0;
                        cnt <= WAIT_CNT_WR - 1;
                        state <= STATE_EXITING_WRITE;
                    end
                end
                
                STATE_EXITING_WRITE:
                begin
                    NOP();
                    if( !cnt ) begin
                        cnt <= WAIT_CNT_PRCA - 1;
                        PRECHARGE_ALL();
                        state <= STATE_PRECHARGING;
                    end
                end

                STATE_PRECHARGING:
                begin
                    NOP();
                    if( !cnt ) begin
                        state <= STATE_IDLE;
                    end
                end
            endcase
        end
    end
endmodule