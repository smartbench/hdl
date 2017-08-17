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
    def __init__ ( self, clk, rst, addr, data, rdy, my_addr):
        self.clk = clk
        self.rst = rst
        self.addr = addr
        self.data = data
        self.rdy = rdy

        self.fifo = []
        self.my_addr = my_addr

    @cocotb.coroutine
    def monitor ( self):
        while True:
            yield FallingEdge(self.clk)
            if( self.rdy.value.integer == 1 and self.addr.value.integer == self.my_addr):
                self.fifo.append(self.data.value.integer)
            yield RisingEdge(self.clk)

class REG_SI_MON:
    def __init__ ( self, clk, rst, addr, data, rdy):
        self.clk = clk
        self.rst = rst
        self.addr = addr
        self.data = data
        self.rdy = rdy

        self.fifo_data = []
        self.fifo_addr = []

    @cocotb.coroutine
    def bus_monitor ( self):
        while True:
            yield FallingEdge(self.clk)
            if( self.rdy.value.integer == 1):
                self.fifo_data.append(self.data.value.integer)
                self.fifo_addr.append(self.addr.value.integer)
            yield RisingEdge(self.clk)


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
    si_rx = SI_Master(dut.clk, dut.rst, dut.rx_data, dut.rx_rdy, dut.rx_ack)
    reg_10 = REG_SI_Slave(dut.clk, dut.rst, dut.register_addr, dut.register_data, dut.register_rdy, 10)
    reg_13 = REG_SI_Slave(dut.clk, dut.rst, dut.register_addr, dut.register_data, dut.register_rdy, 13)
    reg_200 = REG_SI_Slave(dut.clk, dut.rst, dut.register_addr, dut.register_data, dut.register_rdy, 200)

    reg_mon = REG_SI_MON(dut.clk, dut.rst, dut.register_addr, dut.register_data, dut.register_rdy)
    print "------------------------------------------- TWO -------------------------------------------"

    cocotb.fork( Clock(dut.clk,10,units='ns').start() )
    print "------------------------------------------- THREE -------------------------------------------"
    yield Reset(dut)

    print "------------------------------------------- FOUR -------------------------------------------"

    print "I'm writing the fifo"

    si_rx.write(13)
    si_rx.write(0xFF)
    si_rx.write(0xEE)
    si_rx.write(10)
    si_rx.write(0xDD)
    si_rx.write(0xCC)
    si_rx.write(200)
    si_rx.write(0xBB)
    si_rx.write(0xAA)
    si_rx.write(9)
    si_rx.write(0x99)
    si_rx.write(0x88)

    # requests_handler (addr=0x00)
    si_rx.write(0)
    si_rx.write(0x01)
    si_rx.write(0x00)

    cocotb.fork( si_rx.driver() )
    cocotb.fork( reg_10.monitor() )
    cocotb.fork( reg_13.monitor() )
    cocotb.fork( reg_200.monitor() )
    cocotb.fork( reg_mon.bus_monitor() )

    print "I'm starting to send the data"
    for i in range(100): yield RisingEdge(dut.clk)

    # requests_handler (addr=12)
    si_rx.write(12)
    si_rx.write(0x02)
    si_rx.write(0x00)
    for i in range(10): yield RisingEdge(dut.clk)
    si_rx.write(12)
    si_rx.write(0x04)
    si_rx.write(0x00)
    for i in range(10): yield RisingEdge(dut.clk)
    si_rx.write(12)
    si_rx.write(0x08)
    si_rx.write(0x00)
    for i in range(10): yield RisingEdge(dut.clk)
    si_rx.write(12)
    si_rx.write(0xFF)
    si_rx.write(0xFF)
    for i in range(10): yield RisingEdge(dut.clk)

    print "Reg_10: " + repr(reg_10.fifo)
    print "Reg_13: " + repr(reg_13.fifo)
    print "Reg_200: " + repr(reg_200.fifo)
    print "Data: " + repr(reg_mon.fifo_addr)
    print "Addr: " + repr(reg_mon.fifo_data)
    print "I'm at the end"
    #if ( si_rx.fifo != [ i for i in range(100)]):
    #    TestFailure("Simple Interface data != FT245 data")
