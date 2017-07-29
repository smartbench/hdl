import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

@cocotb.coroutine
def nsTimer( t ):
    yield Timer( t, units='ns' )

class ShiftRegister:

    def __init__( self, dut ):
        self.dut = dut
        self.txbyte_fifo = []
        self.dut.ack <= 0
        self.dut.request <= 0

    @cocotb.coroutine
    def startReading( self ):
        self.dut.request <= 1
        yield RisingEdge( self.dut.clk )
        self.dut.request <= 0
        yield RisingEdge( self.dut.clk )

    @cocotb.coroutine
    def driverAndMonitor( self ):
        while True:
            yield RisingEdge( self.dut.request )
            self.dut.ack <= 1

            while self.dut.empty.value.integer != 1:
                yield Timer(1,units='ps')
                self.txbyte_fifo.append( self.dut.tx_data.value.integer )
                yield RisingEdge( self.dut.clk )
                yield Timer(1,units='ps')

            self.dut.ack <=0

class Reg_SI:
    def __init__( self, clk, addr, data, rdy, ack):

        self.clk = clk
        self.addr = addr
        self.data = data
        self.rdy = rdy
        self.ack = ack
        self.addr_fifo = []
        self.data_fifo = []
        self.rdy <= 0


    def new_data( self, addr, data ):
        self.addr_fifo.append(addr)
        self.data_fifo.append(data)

    @cocotb.coroutine
    def driver (self):
        while True:


            while len( self.addr_fifo ) ==0 : yield RisingEdge(self.clk)
            self.addr <= self.addr_fifo.pop(0)

            while len( self.data_fifo ) ==0 : yield RisingEdge(self.clk)
            self.data <= self.data_fifo.pop(0)

            self.rdy <= 1

            yield RisingEdge(self.clk)
            # No espero una chota el ack
            # while self.ack != 1: yield RisingEdge(self.clk)
            self.rdy <= 0
            yield RisingEdge(self.clk)

@cocotb.coroutine
def Reset (dut):
    dut.rst <= 0
    for i in range(10): yield RisingEdge(dut.clk)
    dut.rst <= 1
    yield RisingEdge(dut.clk)
    dut.rst <= 0
    yield RisingEdge(dut.clk)

@cocotb.test()
def top_test( dut ):
    reg_si = Reg_SI( dut.clk, dut.register_addr, dut.register_data, dut.register_rdy, dut.register_ack )
    shift_reg = ShiftRegister(dut)

    cocotb.fork( Clock(dut.clk,10,units='ns').start() )
    yield Reset(dut)

    for i in range(1,11): reg_si.new_data( i,i)

    cocotb.fork( shift_reg.driverAndMonitor() )
    cocotb.fork( reg_si.driver() )

    for i in range(20): yield RisingEdge( dut.clk )

    yield shift_reg.startReading()
    for i in range(100): yield RisingEdge( dut.clk )
