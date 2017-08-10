import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

from random import randint
from math import pi, sin

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

class SI_REG_MASTER:
    def __init__ (self, clk, rst, reg_si_data, reg_si_addr, reg_si_rdy):
        self.clk = clk
        self.rst = rst
        self.reg_si_data = reg_si_data
        self.reg_si_addr = reg_si_addr
        self.reg_si_rdy = reg_si_rdy
        self.fifo_data = []
        self.fifo_addr = []

        self.reg_si_addr <= 0
        self.reg_si_data <= 0
        self.reg_si_rdy <= 0

    def writeReg (self, addr, data):
        self.fifo_addr.append(addr)
        self.fifo_data.append(data)

    @cocotb.coroutine
    def driver (self):
        while True:
            if (len(self.fifo_data)>0):
                self.reg_si_data <= self.fifo_data.pop(0)
                self.reg_si_addr <= self.fifo_addr.pop(0)
                self.reg_si_rdy <= 1
            yield RisingEdge(self.clk)
            self.reg_si_rdy <= 0

class ADC:
    def __init__ (self, clk, data, rdy):
        self.clk = clk
        self.data = data
        self.rdy = rdy

        self.fifo = []
        self.data <= 0
        self.rdy <= 0

    def clear(self):
        self.fifo = []

    def write(self, data_i):
        self.fifo.append(data_i)

    @cocotb.coroutine
    def sampling (self):
        while True:
            if (len(self.fifo) > 0):
                self.data <= self.fifo.pop(0)
                self.rdy <= 1
            yield RisingEdge(self.clk)
            self.rdy <= 0
            for i in range(3): yield RisingEdge(self.clk)


class RAM_Controller:
    def __init__ (self, clk, we, data_in, rdy):
        self.clk = clk
        self.we = we
        self.data_in = data_in
        self.rdy = rdy
        self.fifo = []

    @cocotb.coroutine
    def run(self):
        while True:
            yield FallingEdge(self.clk)
            if(self.we.value.integer == 1 and self.rdy.value.integer == 1):
                self.fifo.append(self.data_in)
            yield RisingEdge(self.clk)

class TX_PROTOCOL:
    def __init__ (self, clk, rqst_trigger_status, trigger_status_data, trigger_status_rdy, trigger_status_eof, trigger_status_ack):
        self.clk = clk
        self.rqst_trigger_status = rqst_trigger_status
        self.trigger_status_data = trigger_status_data
        self.trigger_status_rdy = trigger_status_rdy
        self.trigger_status_eof = trigger_status_eof
        self.trigger_status_ack = trigger_status_ack

        self.fifo = []

        self.rqst_trigger_status <= 0
        self.trigger_status_ack <= 0

    @cocotb.coroutine
    def request_data (self):
        self.rqst_trigger_status <= 1
        yield RisingEdge(self.clk)
        self.rqst_trigger_status <= 0
        yield RisingEdge(self.clk)
        yield FallingEdge(self.clk)
        #print "requesting..."
        while self.trigger_status_eof.value.integer == 0:
            if(self.trigger_status_rdy.value.integer == 1):
                self.fifo.append(self.trigger_status_data.value.integer)
                self.trigger_status_ack <= 1
            else:
                self.trigger_status_ack <= 0
            yield RisingEdge(self.clk)
        self.trigger_status_ack <= 0
        #print "request finished..."

class RQST_HANDLER:
    def __init__(self, clk, start, stop, rqst_trigger_status):
        self.clk = clk
        self.start = start
        self.stop = stop
        #self.rqst_ch1 = rqst_ch1
        #self.rqst_ch2 = rqst_ch2
        self.rqst_trigger_status = rqst_trigger_status

        self.start <= 0
        self.stop <= 0
        #self.rqst_ch1 <= 0
        #self.rqst_ch2 <= 0
        self.rqst_trigger_status <= 0

    @cocotb.coroutine
    def rqst_start(self):
        self.start <= 1
        self.stop <= 0
        yield RisingEdge(self.clk)
        self.start <= 0
        yield RisingEdge(self.clk)

    @cocotb.coroutine
    def rqst_stop(self):
        self.stop <= 1
        yield RisingEdge(self.clk)

    @cocotb.coroutine
    def rqst_trigger_status(self):
        self.rqst_trigger_status <= 1
        yield RisingEdge(self.clk)
        self.rqst_trigger_status <= 0
        yield RisingEdge(self.clk)



@cocotb.coroutine
def Start(dut):
    dut.start <= 1
    yield RisingEdge(dut.clk)
    dut.start <= 0
    yield RisingEdge(dut.clk)


@cocotb.coroutine
def Reset(dut):
    dut.rst <= 0
    for i in range(10): yield RisingEdge(dut.clk)
    dut.rst <= 1
    yield RisingEdge(dut.clk)
    dut.rst <= 0
    yield RisingEdge(dut.clk)

@cocotb.test()
def test (dut):
    print "------------------------------------------- ONE -------------------------------------------"

    ADDR_PRETRIGGER = 0
    ADDR_NUM_SAMPLES = 1
    ADDR_TRIGGER_VALUE = 2
    ADDR_TRIGGER_SETTINGS = 3

    EDGE_POS = 0
    EDGE_NEG = 1
    SRC_XX = (0 << 1)
    SRC_CH1 = (1 << 1)
    SRC_CH2 = (2 << 1)
    SRC_EXT = (3 << 1)
    #dut.num_samples <= 24       # number of samples
    #dut.pre_trigger <= 8        # number of samples before trigger
    #dut.trigger_value <= 170    # trigger value

    ch1_data = dut.ch1_in
    ch2_data = dut.ch2_in
    ch1_rdy = dut.adc_ch1_rdy
    ch2_rdy = dut.adc_ch2_rdy
    ext_in = dut.ext_in

    ram_ch1 = RAM_Controller(dut.clk, dut.we, ch1_data, ch1_rdy)
    ram_ch2 = RAM_Controller(dut.clk, dut.we, ch2_data, ch2_rdy)

    adc_ch1 = ADC(dut.clk, ch1_data, ch1_rdy)
    adc_ch2 = ADC(dut.clk, ch2_data, ch2_rdy)

    tx_protocol = TX_PROTOCOL(dut.clk, dut.rqst_trigger_status, dut.trigger_status_data, dut.trigger_status_rdy, dut.trigger_status_eof, dut.trigger_status_ack)

    si_reg_master = SI_REG_MASTER( dut.clk, dut.rst, dut.register_data, dut.register_addr, dut.register_rdy)

    rqst_handler = RQST_HANDLER( dut.clk, dut.start, dut.stop, dut.rqst_trigger_status)

    si_reg_master.writeReg( ADDR_PRETRIGGER , 8 )
    si_reg_master.writeReg( ADDR_NUM_SAMPLES , 24 )
    si_reg_master.writeReg( ADDR_TRIGGER_VALUE , 170 )
    si_reg_master.writeReg( ADDR_TRIGGER_SETTINGS , SRC_CH1 | EDGE_POS )

    for t in range(200):
        x1 = 128 + int(100 * sin(2*pi*1e6*t*20e-9))
        x2 = 128 - int(050 * sin(2*pi*1e6*t*20e-9))
        adc_ch1.write(x1)
        adc_ch2.write(x2)

    cocotb.fork( Clock(dut.clk,10,units='ns').start() )

    yield Reset(dut)


    cocotb.fork(ram_ch1.run())
    cocotb.fork(ram_ch2.run())
    cocotb.fork(adc_ch1.sampling())
    cocotb.fork(adc_ch2.sampling())
    cocotb.fork(si_reg_master.driver())

    # cocotb.fork( () )
    # cocotb.fork( () )
    # cocotb.fork( () )
    # cocotb.fork( () )
    # cocotb.fork( () )

    for i in range(10): yield RisingEdge(dut.clk)

    yield rqst_handler.rqst_start()
    for i in range(500): yield RisingEdge(dut.clk)
    yield rqst_handler.rqst_stop()
    yield tx_protocol.request_data()
    for i in range(500): yield RisingEdge(dut.clk)

    print "-----------------------------------------"
    print "LEN fifo Tx_Protocol = " + repr(len(tx_protocol.fifo))
    for i in range(len(tx_protocol.fifo)):
        print "Fifo Read: " + repr(tx_protocol.fifo.pop(0))

    print "-----------------------------------------"
    print "LEN fifo Ram CH1 = " + repr(len(ram_ch1.fifo))
    #for i in range(len(ram_ch1.fifo)):
    #    print "Fifo Read: " + repr(ram_ch1.fifo.pop(0))

    print "-----------------------------------------"
    print "LEN fifo Ram CH2 = " + repr(len(ram_ch2.fifo))
    #for i in range(len(ram_ch2.fifo)):
    #    print "Fifo Read: " + repr(ram_ch2.fifo.pop(0))

    print "I'm at the end"
    #if ( si_rx.fifo != [ i for i in range(100)]):
    #    TestFailure("Simple Interface data != FT245 data")
