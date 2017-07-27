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

class Register:
    def __init__ ( self, clk, addr, registers, rdy, ack ):
        self.clk = clk
        self.addr = addr
        self.registers = registers
        self.addr_fifo = []
        self.data_fifo = []
        self.rdy = rdy

    @cocotb.coroutine
    def monitor( self ):
        while True:
            while ( self.rdy.value.integer != 1 ): yield RisingEdge(self.clk)

            # addr and data bus is ready
            addr = self.addr
            self.addr_fifo.append( addr.value.integer )
            yield RisingEdge( self.clk )
            # Next clock data is updated
            self.data_fifo.append( self.read_register( addr.value.integer ) )

    def read_register( self, addr ):
        shift = (addr-1) * 16
        print shift
        mask = 0b1111111111111111
        if shift>0:
            return ( ( self.registers.value ) >> shift ) & mask
        else:
            return self.registers.value.integer & mask


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

    reg = Register( dut.clk, dut.register_addr, dut.registers, dut.register_rdy, dut.register_ack )
    reg_si = Reg_SI( dut.clk, dut.register_addr, dut.register_data, dut.register_rdy, dut.register_ack )

    cocotb.fork( Clock(dut.clk,10,units='ns').start() )
    yield Reset(dut)

    for i in range(1,11): reg_si.new_data( i,i)

    cocotb.fork( reg_si.driver() )
    cocotb.fork( reg.monitor() )

    for i in range(152): yield RisingEdge( dut.clk )

    print reg.addr_fifo, reg.data_fifo

    if ( reg.addr_fifo != reg.data_fifo ):
        print "fuck"
        raise TestFailure("Houston, we have a problem here...")
