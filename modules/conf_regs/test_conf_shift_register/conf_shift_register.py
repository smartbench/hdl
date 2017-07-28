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
        self.registers_fifo = []
        self.txbyte_fifo = []
        self.dut.ack <= 0
        self.dut.request <= 0

    def next_register_value( self, reg ):
        self.registers_fifo.append( reg )

    @cocotb.coroutine
    def driverAndMonitor( self ):
        while True:
            while len( self.registers_fifo ) == 0: yield RisingEdge( self.dut.clk )
            self.dut.registers <= self.registers_fifo.pop( 0 )
            self.dut.request <= 1
            yield RisingEdge( self.dut.clk )
            self.dut.request <= 0
            self.dut.ack <= 1
            #yield RisingEdge( self.dut.clk )

            while self.dut.empty.value.integer != 1:
                #print format(self.dut.shift_register.value.integer,'0x')
                yield Timer(1,units='ps')
                self.txbyte_fifo.append( self.dut.tx_data.value.integer )
                yield RisingEdge( self.dut.clk )
                yield Timer(1,units='ps')


            self.dut.ack <=0

@cocotb.coroutine
def Reset (dut):
    dut.rst <= 0
    for i in range(10): yield RisingEdge(dut.clk)
    dut.rst <= 1
    yield RisingEdge(dut.clk)
    dut.rst <= 0
    yield RisingEdge(dut.clk)

@cocotb.test()
def conf_shift_register_test (dut):
    shift_reg = ShiftRegister(dut)

    cocotb.fork( Clock(dut.clk,10,units='ns').start() )
    yield Reset(dut)

    shift_reg.next_register_value( 0xaaaa999988887777666655554444333322221111 )

    cocotb.fork( shift_reg.driverAndMonitor() )

    for i in range(50): yield RisingEdge( dut.clk )

    print shift_reg.txbyte_fifo
    if shift_reg.txbyte_fifo != [   0x11, 0x11, 0x22, 0x22, 0x33, 0x33, 0x44, 0x44, 0x55, 0x55,
                                    0x66, 0x66, 0x77, 0x77, 0x88, 0x88, 0x99, 0x99, 0xaa, 0xaa ]:
        raise TestFailure("Houston, we have a problem here...")
