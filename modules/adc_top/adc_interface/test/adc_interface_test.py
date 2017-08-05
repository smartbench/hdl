import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

class SI_Slave:
    def __init__ ( self, clk, rst , data, rdy, ack):
        self.data = data
        self.rdy = rdy
        self.ack = ack
        self.fifo = []
        self.clk = clk
        self.rst = rst
        self.ack <= 0

    @cocotb.coroutine
    def monitor ( self):

        # Skip first sampled data
        while self.rdy !=1: yield RisingEdge(self.clk)
        yield RisingEdge(self.clk)

        # Real data
        while True:
            while self.rdy!=1: yield RisingEdge(self.clk)
            self.fifo.append(self.data.value.integer)
            yield RisingEdge(self.clk)

    @cocotb.coroutine
    def acknowledgment ( self ):
        while True:
            yield Edge(self.rdy)
            self.ack <= self.rdy.value.integer

class Adc:
    def __init__ ( self, dut ):
        self.dut = dut

        self.fifo = []
        self.dut.ADC_data <= 0
        self.dut.SI_data <= 0

    def takeSample(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def driver (self):
        while True:
            yield RisingEdge(self.dut.clk_o)
            nsTimer(10)
            self.dut.ADC_data <= 0 # invalid data here
            nsTimer(9.5)
            if ( len(self.fifo) > 0 ):
                self.dut.ADC_data = self.fifo.pop(0)
                #print 'poping'
            else:
                self.dut.ADC_data = 0

@cocotb.coroutine
def Reset (dut):
    dut.reset <= 0
    for i in range(10): yield RisingEdge(dut.clk_i)
    dut.reset <= 1
    yield RisingEdge(dut.clk_i)
    dut.reset <= 0
    dut.decimation_factor <= 0
    yield RisingEdge(dut.clk_i)

@cocotb.test()
def adc_interface_test (dut):

    adc = Adc(dut)
    si_adc = SI_Slave( dut.clk_i, dut.reset, dut.SI_data, dut.SI_rdy, dut.SI_ack )

    cocotb.fork( Clock(dut.clk_i,10,units='ns').start() )
    yield Reset(dut)

    #print 'Taking samples'
    for i in range(302): adc.takeSample(i)

    cocotb.fork( adc.driver() )
    cocotb.fork( si_adc.acknowledgment() )
    cocotb.fork( si_adc.monitor() )

    for i in range(152): yield RisingEdge(dut.clk_o)

    if( si_adc.fifo != [i for i in range(150)]):
        print "Houston, we have a problem here ..."
        print si_adc.fifo
        raise TestFailure("Simple Interface data != ADC samples")

    dut.decimation_factor <= 1

    for i in range(150): yield RisingEdge(dut.clk_o)

    if( si_adc.fifo != [i%256 for i in range(300)]):
        print "Houston, we have a problem here ... N2"
        print si_adc.fifo
        raise TestFailure("Simple Interface data != ADC samples")
