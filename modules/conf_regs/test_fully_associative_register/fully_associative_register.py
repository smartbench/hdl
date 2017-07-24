import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

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
            if len( self.addr_fifo ) > 0:
                self.addr <= self.addr_fifo.pop(0)
            else:
                self.addr <= 0

            if len( self.data_fifo ) > 0:
                self.data <= self.data_fifo.pop(0)
            else:
                self.data <= 0

            self.rdy <= 1

            yield RisingEdge(self.clk)
            while self.ack != 1: yield RisingEdge(self.clk)
            self.rdy <= 0
            yield RisingEdge(self.clk)

class Register:
    def __init__ ( self, clk, addr, si_data, data, rdy, ack, myAddr ):
        self.clk = clk
        self.addr = addr
        self.data = data
        self.si_data = si_data
        self.myAddr = myAddr
        self.data_fifo = []
        self.rdy = rdy

    @cocotb.coroutine
    def monitor( self ):
        while True:
            while ( self.rdy.value.integer != 1 ): yield RisingEdge(self.clk)
            if ( self.addr == self.myAddr ):
                print self.data.value.integer
                print self.si_data.value.integer

                yield RisingEdge(self.clk)
                print self.data.value.integer
                print self.si_data.value.integer
                self.data_fifo.append(self.data.value.integer)


@cocotb.coroutine
def Reset (dut):
    dut.rst <= 0
    for i in range(10): yield RisingEdge(dut.clk)
    dut.rst <= 1
    yield RisingEdge(dut.clk)
    dut.rst <= 0
    yield RisingEdge(dut.clk)

@cocotb.test()
def fully_associative_register_test (dut):

    reg = Register( dut.clk, dut.si_addr, dut.si_data, dut.data, dut.si_rdy, dut.si_ack, dut.MY_ADDR )
    reg_si = Reg_SI( dut.clk, dut.si_addr, dut.si_data, dut.si_rdy, dut.si_ack )

    cocotb.fork( Clock(dut.clk,10,units='ns').start() )
    yield Reset(dut)

    print 'I\'m here 0'
    for i in range(300): reg_si.new_data( i,i)

    cocotb.fork( reg_si.driver() )
    cocotb.fork( reg.monitor() )
    #cocotb.fork( reg.others_acknowledgments() )

    for i in range(152): yield RisingEdge( dut.clk )

    if reg.data_fifo != dut.MY_ADDR:
        print reg.data_fifo
        raise TestFailure("Houston, we have a problem here...")
