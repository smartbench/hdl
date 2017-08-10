import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

class ADC:
    def __init__ ( self, dut ):
        self.dut = dut
        self.fifo = []
        self.dut.adc_data_i <= 0

    def takeSample(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def driver (self):
        while True:
            yield RisingEdge(self.dut.clk_o)
            nsTimer(10)
            self.dut.adc_data_i <= 0 # invalid data here
            nsTimer(9.5)
            if ( len(self.fifo) > 0 ):
                self.dut.adc_data_i = self.fifo.pop(0)
                #print 'poping' # Pooping? there is no more toilet paper!
            else:
                self.dut.adc_data_i <= 0

class FT245_:
    def __init__ (self, dut):
        self.dut = dut



@cocotb.coroutine
def Reset (dut):
    dut.rst <= 0
    for i in range(10): yield RisingEdge(dut.clk_i)
    dut.rst <= 1
    yield RisingEdge(dut.clk_i)
    dut.rst <= 0
    yield RisingEdge(dut.clk_i)

@cocotb.test()
def adc_block_test (dut):

    REG_ADDR_ADC_DF_L = 0
    REG_ADDR_ADC_DF_H = 1
    REG_ADDR_MOV_AVE_K = 2
    
    DF = 2
    K = 1
    
    adc = Adc(dut)
    ft245 = FT245(dut)
    
    cocotb.fork( Clock(dut.clk_i,10,units='ns').start() )
    yield Reset(dut)

    cocotb.fork( adc.driver() )
    cocotb.fork( ft245.driver() )

    for i in range(1000): yield RisingEdge(dut.clk_100M)

