import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

from random import randint


@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

class SI_Master:
    def __init__ ( self, clk, rst , data, rdy, ack):
        self.data = data
        self.rdy = rdy
        self.ack = ack
        self.fifo = []
        self.clk = clk
        self.rst = rst
        self.rdy <= 0
        self.data <= 0

    def write(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def driver (self):
        while True:
            yield RisingEdge(self.clk)
            if len(self.fifo) > 0 :
                self.rdy <= 1
                self.data <= self.fifo.pop(0)
                while self.ack.value.integer != 1 : yield RisingEdge(self.clk)
                self.rdy <= 0

class REG_SI_Slave:
    def __init__ ( self, clk, rst, addr, data, rdy, ack):
        self.addr = addr
        self.data = data
        self.rdy = rdy
        self.ack = ack
        self.fifoaddr = []
        self.fifodata = []
        self.clk = clk
        self.rst = rst
        self.ack <= 0


    @cocotb.coroutine
    def monitor ( self):
        while True:
            self.ack <= 0
            yield RisingEdge(self.rdy)
            yield RisingEdge(self.clk)
            #for i in range(randint(0,15)): yield RisingEdge(self.clk)
            self.ack <= 1
            #yield RisingEdge(self.clk) # IP: don't like it
            self.fifodata.append(self.data.value.integer)
            self.fifoaddr.append(self.addr.value.integer)
            yield RisingEdge(self.clk)  # IP: like it

@cocotb.coroutine
def Reset (dut):
    dut.rst <= 0
    for i in range(10): yield RisingEdge(dut.clk)
    dut.rst <= 1
    yield RisingEdge(dut.clk)
    dut.rst <= 0
    yield RisingEdge(dut.clk)

@cocotb.test()
def test (dut):
    si_rx = SI_Master(dut.clk,dut.rst,dut.rx_data,dut.rx_rdy,dut.rx_ack)
    si_reg = REG_SI_Slave(dut.clk,dut.rst,dut.register_addr,dut.register_data,dut.register_rdy,dut.register_ack)
    cocotb.fork(Clock(dut.clk,10,units='ns').start())
    yield Reset(dut)

    print "I'm writing the fifo"
    for i in range(150): si_rx.write(i)
    cocotb.fork(si_rx.driver() )
    cocotb.fork(si_reg.monitor() )

    print "I'm starting to send the data"
    for i in range(600): yield RisingEdge(dut.clk)

    print si_reg.fifoaddr
    print si_reg.fifodata
    print "I'm at the end"
    #if ( si_rx.fifo != [ i for i in range(100)]):
    #    TestFailure("Simple Interface data != FT245 data")
