import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

RD_TO_DATA = 14.0
RFX_INACTIVE = 49.0

WR_TO_INACTIVE = 14.0
TXE_INACTIVE = 50.0

ADDR_REQUESTS =                 0
ADDR_SETTINGS_CHA =             1
ADDR_SETTINGS_CHB =             2
ADDR_DAC_CHA =                  3
ADDR_DAC_CHB =                  4
ADDR_TRIGGER_SETTINGS =         5
ADDR_TRIGGER_VALUE =            6
ADDR_NUM_SAMPLES =              7
ADDR_PRETRIGGER =               8
ADDR_ADC_CLK_DIV_CHA_L =        9
ADDR_ADC_CLK_DIV_CHA_H =        10
ADDR_ADC_CLK_DIV_CHB_L =        11
ADDR_ADC_CLK_DIV_CHB_H =        12
ADDR_N_MOVING_AVERAGE_CHA =     13
ADDR_N_MOVING_AVERAGE_CHB =     14

DF = 2
K = 1

#from "../../ft245/test_block_io/ft245_block.py" import Ft245

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

class ADC:
    def __init__ ( self, adc_data, adc_clk):
        self.adc_data = adc_data
        self.adc_clk = adc_clk

        self.fifo = []
        self.adc_data <= 0

    def takeSample(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def driver (self):
        while True:
            yield RisingEdge(self.adc_clk)
            nsTimer(10)
            self.self.adc_data <= 0 # invalid data here
            nsTimer(9.5)
            if ( len(self.fifo) > 0 ):
                self.self.adc_data = self.fifo.pop(0)
                #print 'poping' # Pooping? there is no more toilet paper!
            else:
                self.self.adc_data <= 0

class FT245:
    def __init__ (self,dut):
        self.dut = dut

        self.tx_fifo = []
        self.rx_fifo = []

        self.dut.rxf_245 <= 1
        self.dut.txe_245 <= 0
        #self.dut.in_out_245 <= 0

    def write (self,val):
        self.rx_fifo.append(val)

    def write_reg(self, addr, data):
        self.rx_fifo.append( addr )
        self.rx_fifo.append( data % 256 )   # first LOW
        self.rx_fifo.append( (data >> 8) % 256) # then HIGH

    @cocotb.coroutine
    def tx_monitor (self):
        print ("-----------------------------------------------")
        yield nsTimer(TXE_INACTIVE)
        while True:
            if True: # if BufferNotFull:
                self.dut.txe_245 <= 0
                if self.dut.wr_245.value.integer == 1: yield FallingEdge(self.dut.wr_245)
                yield Timer(1, units='ps')
                #print ("{WR_245, TXE_245} = " + repr(self.dut.wr_245.value.integer) + repr(self.dut.txe_245.value.integer) )
                self.tx_fifo.append(self.dut.in_out_245.value.integer)
                #print ("-----------------------------------------------")
                print ("FDTI TX: " + repr(self.dut.in_out_245.value.integer))
                #print ("-----------------------------------------------")
                yield nsTimer(WR_TO_INACTIVE)
                self.dut.txe_245 <= 1
            yield nsTimer(TXE_INACTIVE)

    @cocotb.coroutine
    def rx_driver (self):
        while True:
            if(len(self.rx_fifo) > 0):
                self.dut.rxf_245 <= 0
                if(self.dut.rx_245.value.integer == 1): yield FallingEdge(self.dut.rx_245)
                yield nsTimer(RD_TO_DATA)
                #self.dut.in_out_245 <= 0
                aux = self.rx_fifo.pop(0)
                self.dut.in_out_245 <= aux #self.rx_fifo.pop(0)
                #print "-----------------------------------------------"
                #print "AUX = " + repr(aux)
                yield Timer(1,units='ps')
                #print "FDTI RX: " + repr(self.dut.in_out_245.value.integer)
                #print "-----------------------------------------------"
                if(self.dut.rx_245.value.integer == 0): yield RisingEdge(self.dut.rx_245)
                #self.dut.in_out_245 <= 0
                yield nsTimer(14)
                self.dut.rxf_245 <= 1
            yield nsTimer(RFX_INACTIVE)


@cocotb.coroutine
def Reset (dut):
    dut.rst <= 0
    for i in range(10): yield RisingEdge(dut.clk_i)
    dut.rst <= 1
    yield RisingEdge(dut.clk_i)
    dut.rst <= 0
    yield RisingEdge(dut.clk_i)

@cocotb.test()
def test (dut):

    adc_chA = ADC(dut.chA_adc_in, dut.chA_adc_clk_o)
    adc_chB = ADC(dut.chB_adc_in, dut.chB_adc_clk_o)
    ft245 = FT245(dut)

    cocotb.fork( Clock(dut.clk_i,10,units='ns').start() )
    yield Reset(dut)

    cocotb.fork( adc_chA.driver() )
    cocotb.fork( adc_chB.driver() )
    cocotb.fork( ft245.tx_monitor() )
    cocotb.fork( ft245.rx_driver() )

    for i in range(1000): yield RisingEdge(dut.clk_100M)
