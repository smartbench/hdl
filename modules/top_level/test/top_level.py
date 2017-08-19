import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

from math import pi, sin
from random import randint

RD_TO_DATA = 14.0
RFX_INACTIVE = 49.0
WR_TO_INACTIVE = 14.0
TXE_INACTIVE = 50.0
TX_FIFO_MAX = 100

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

RQST_START_BIT  = (1 << 0)
RQST_STOP_BIT   = (1 << 1)
RQST_CHA_BIT    = (1 << 2)
RQST_CHB_BIT    = (1 << 3)
RQST_TRIG_BIT   = (1 << 4)
RQST_RST_BIT    = (1 << 5)

NOISE_MAX       = 8

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

    def write(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def driver (self):
        while True:
            yield RisingEdge(self.adc_clk)
            nsTimer(10)
            self.adc_data <= 0 # invalid data here
            nsTimer(9.5)
            if ( len(self.fifo) > 0 ):
                #aux = self.fifo.pop(0)
                #self.adc_data <= aux
                #print "DATA = " + repr(aux)
                self.adc_data <= self.fifo.pop(0)
                #print 'poping' # Pooping? there is no more toilet paper!
            else:
                self.adc_data <= 0

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
    def wait_bytes(self, n):
        while(len(self.tx_fifo) < n): yield Timer(1, units='ns') # RisingEdge(self.dut.clk_o)

    def read_byte(self, data):
        if(len(self.tx_fifo) > 0):
            data <= self.tx_fifo.pop(0)
            return 0
        return -1

    def read_data(self, data, n=0):
        i = 0
        if(n > 0):
            #yield self.wait_bytes(n)
            while(i < n and len(self.tx_fifo) > 0):
                data.append(self.tx_fifo.pop(0))
                i = i + 1
        else:
            while(len(self.tx_fifo) > 0):
                data.append(self.tx_fifo.pop(0))
                i = i + 1
        return i

    # @cocotb.coroutine
    # def driver_tx_rx (self):
    #     while True:
    #         print ("AAAAAAAAAAAAAAAAAAAAAAAAAAA")
    #         if(len(self.tx_fifo) < TX_FIFO_MAX): self.dut.txe_245 <= 0
    #         else: self.dut.txe_245 <= 1
    #
    #         if(len(self.rx_fifo) > 0): self.dut.rxf_245 <= 0
    #         else: self.dut.rxf_245 <= 1
    #         print ("BBBBBBBBBBBBBBBBBBBBBBBBBBBBB")
    #
    #         if(self.dut.txe_245.value.integer == 0 and self.dut.wr_245.value.integer == 0):
    #             # start tx sequence
    #             print ("CCCCCCCCCCCCCCCCCCCCCC")
    #             yield Timer(1, units='ps')
    #             self.tx_fifo.append(self.dut.in_out_245.value.integer)
    #             print ("FDTI TX: " + repr(self.dut.in_out_245.value.integer))
    #             yield nsTimer(14+WR_TO_INACTIVE) #T6+...
    #             if (self.dut.wr_245.value.integer == 0): yield RisingEdge(self.dut.wr_245)
    #             self.dut.txe_245 <= 1
    #             yield nsTimer(TXE_INACTIVE)
    #         else:
    #             if(self.dut.rxf_245.value.integer == 0 and self.dut.rx_245.value.integer == 0):
    #                 print ("DDDDDDDDDDDDDDDDDDDDDDDDDD")
    #                 yield Timer(1, units='ps')
    #                 yield nsTimer(RD_TO_DATA)
    #                 aux = self.rx_fifo.pop(0)
    #                 self.dut.in_out_245 <= aux #self.rx_fifo.pop(0)
    #                 #print "AUX = " + repr(aux)
    #                 yield Timer(1,units='ps')
    #                 if(self.dut.rx_245.value.integer == 0): yield RisingEdge(self.dut.rx_245)
    #                 yield nsTimer(14)
    #                 self.dut.rxf_245 <= 1
    #                 yield nsTimer(RFX_INACTIVE)
    #             else:
    #                 print ("EEEEEEEEEEEEEEEEEEEEEEEEE")
    #                 yield Timer(10, units='ns')

    @cocotb.coroutine
    def tx_monitor (self):
        print ("-----------------------------------------------")
        yield nsTimer(TXE_INACTIVE)
        while True:
            if True: # if BufferNotFull:
                self.dut.txe_245 <= 0
                if self.dut.wr_245.value.integer == 1: yield FallingEdge(self.dut.wr_245)
                yield Timer(1, units='ps')
                self.tx_fifo.append(self.dut.in_out_245.value.integer)
                #print ("FDTI TX: " + repr(self.dut.in_out_245.value.integer))
                if(self.dut.in_out_245.value.integer > 0): print ("FDTI TX: " + repr(self.dut.in_out_245.value.integer))
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
                aux = self.rx_fifo.pop(0)
                self.dut.in_out_245 <= aux #self.rx_fifo.pop(0)
                #print "AUX = " + repr(aux)
                yield Timer(1,units='ps')
                if(self.dut.rx_245.value.integer == 0): yield RisingEdge(self.dut.rx_245)
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
    i = 0
    data = []

    adc_chA = ADC(dut.chA_adc_in, dut.chA_adc_clk_o)
    adc_chB = ADC(dut.chB_adc_in, dut.chB_adc_clk_o)
    ft245 = FT245(dut)

    cocotb.fork( Clock(dut.clk_i,10,units='ns').start() )
    yield Reset(dut)

    cocotb.fork( adc_chA.driver() )
    cocotb.fork( adc_chB.driver() )
    cocotb.fork( ft245.tx_monitor() )
    cocotb.fork( ft245.rx_driver() )
    #cocotb.fork( ft245.driver_tx_rx() )

    # load adc buffers
    # add rand!
    for t in range(10000):
        x1 = 128 + int(100 * sin(2*pi*1e6*t*20e-9)) + randint(-NOISE_MAX, NOISE_MAX)
        x2 = 128 - int(050 * sin(2*pi*1e6*t*20e-9)) + randint(-NOISE_MAX, NOISE_MAX)
        if x1 < 0: x1 = 0
        if x2 < 0: x2 = 0
        if x1 > 256: x1 = 256
        if x2 > 256: x2 = 256
        adc_chA.write(x1)
        adc_chB.write(x2)


    # initial config
    ft245.write_reg(ADDR_SETTINGS_CHA,1)
    ft245.write_reg(ADDR_SETTINGS_CHB,255)
    ft245.write_reg(ADDR_DAC_CHA,127)
    ft245.write_reg(ADDR_DAC_CHB,127)
    ft245.write_reg(ADDR_TRIGGER_SETTINGS,2)
    ft245.write_reg(ADDR_TRIGGER_VALUE,150)
    ft245.write_reg(ADDR_NUM_SAMPLES,200)
    ft245.write_reg(ADDR_PRETRIGGER,80)
    ft245.write_reg(ADDR_ADC_CLK_DIV_CHA_L,4)
    ft245.write_reg(ADDR_ADC_CLK_DIV_CHA_H,0)
    ft245.write_reg(ADDR_ADC_CLK_DIV_CHB_L,4)
    ft245.write_reg(ADDR_ADC_CLK_DIV_CHB_H,0)
    ft245.write_reg(ADDR_N_MOVING_AVERAGE_CHA,1)
    ft245.write_reg(ADDR_N_MOVING_AVERAGE_CHB,1)
    for i in range(1000): yield RisingEdge(dut.clk_100M)

    ft245.write_reg(ADDR_REQUESTS, RQST_START_BIT)
    for i in range(100): yield RisingEdge(dut.clk_100M)
    #for i in range(10): yield RisingEdge(dut.clk_100M)
    ft245.write_reg(ADDR_REQUESTS, RQST_TRIG_BIT)
    yield ft245.wait_bytes(1)
    i = ft245.read_data(data, 1)
    print ("read " + repr(i) + " bytes, data= " + str(data))
    for i in range(2000): yield RisingEdge(dut.clk_100M)
    ft245.write_reg(ADDR_REQUESTS, RQST_TRIG_BIT)
    yield ft245.wait_bytes(1)
    i = ft245.read_data(data, 1)
    print ("read " + repr(i) + " bytes, data= " + str(data))
