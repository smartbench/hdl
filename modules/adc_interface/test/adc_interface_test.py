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
        while True:
            self.ack <= 0
            yield RisingEdge(self.rdy)
            #for i in range(randint(0,15)): yield RisingEdge(self.clk)
            yield RisingEdge(self.clk)
            self.ack <= 1
            #yield RisingEdge(self.clk)
            self.fifo.append(self.data.value.integer)

class Adc:
    def __init__ ( self, dut ):
        self.dut = dut
        # self.data = data
        # self.clk = clk
        # self.oe = oe
        self.fifo = []

    def takeSample(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def driver (self):
        while True:
            yield RisingEdge(self.clk_i)
            nsTimer(10)
            self.data= "invalid"
            nsTimer(9.5)
            self.data=self.fifo.pop(0)

@cocotb.coroutine
def Reset (dut):
    self.dut.reset <= 0
    for i in range(10): yield RisingEdge(self.dut.clk_i)
    self.dut.reset <= 1
    yield RisingEdge(self.dut.clk_i)
    self.dut.reset <= 0
    self.dut.decimation_factor <= 0
    yield RisingEdge(self.dut.clk_i)


@cocotb.test()
def adc_interface_test (dut):
    adc = Adc(dut)
    si_adc = SI_Slave( dut.clk_i, dut.reset, dut.SI_data, dut.SI_rdy, dut.SI_ack )
    cocotb.fork( Clock(dut.clk_i,10,units='ns').start() )
    yield Reset(dut)
    for i in range(150): adc.takeSample(i)
    cocotb.fork( adc.driver() )
    cocotb.fork( si_adc.monitor() )

    for i in range(150): yield RisingEdge(dut.clk_i)
    if( si_adc.fifo != [i for i in range(150)]):
        TestFailure("Simple Interface data != ADC samples")
