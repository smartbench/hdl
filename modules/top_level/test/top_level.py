import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError
from cocotb.binary import BinaryValue

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

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

class ADC:
    def __init__ ( self, adc_data, adc_clk):
        self.adc_data = adc_data
        self.adc_clk = adc_clk

        self.fifo = []
        self.adc_data <= 0

        self.analog_signal = 9

    def write(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def driver (self):
        while True:
            yield RisingEdge(self.adc_clk)
            nsTimer(10)
            self.adc_data <= 0 # invalid data here
            nsTimer(9.5)
            #print("ADC={}".format(self.analog_signal))
            self.adc_data <= self.analog_signal


    @cocotb.coroutine
    def generator(self, time_res, function):
        # time_res is the time resolution in ns (lower time_res simulates a "more analog" input signal)
        # function is a reference to the function that generates the signal
        aux = 0
        t = 0
        while True:
            aux = int (function(t))
            #print "AnalogInt={}\tAnalog={}".format(aux, function(t))
            if aux < 0: aux = 0
            if aux > 255: aux = 255
            self.analog_signal = aux
            yield nsTimer(time_res)
            #print "AnalogSignalLoaded={}".format(self.analog_signal)
            t = t + time_res


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
    def wait_bytes(self, n, timeout=0): #timeout in ns
        step = 1    # in nanoseconds
        i = 0
        while(len(self.tx_fifo) < n and (timeout == 0 or i < timeout)):
            yield Timer(step, units='ns') # RisingEdge(self.dut.clk_o)
            i = i + step

    def read_byte(self, data):
        if(len(self.tx_fifo) > 0):
            data <= self.tx_fifo.pop(0)
            return 0
        return -1

    def append_data(self, data, n=0):
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

    def read_data(self, data, n=0):
        del data[:]
        return self.append_data(data,n)


    @cocotb.coroutine
    def driver_tx_rx (self):
        highZ = BinaryValue()
        highZ.binstr = "zzzzzzzz"
        while True:
            if(len(self.tx_fifo) < TX_FIFO_MAX): self.dut.txe_245 <= 0
            else: self.dut.txe_245 <= 1

            if(len(self.rx_fifo) > 0): self.dut.rxf_245 <= 0
            else: self.dut.rxf_245 <= 1

            if(self.dut.txe_245.value.integer == 0 and self.dut.wr_245.value.integer == 0):
                self.dut.rxf_245 <= 1 # TX --> then NOT RX
                # start tx sequence
                self.dut.in_out_245 <= highZ
                yield Timer(1, units='ps')
                self.tx_fifo.append(self.dut.in_out_245.value.integer)
                #print ("FDTI TX: " + repr(self.dut.in_out_245.value.integer))
                yield nsTimer(14+WR_TO_INACTIVE) #T6+...
                if (self.dut.wr_245.value.integer == 0): yield RisingEdge(self.dut.wr_245)
                self.dut.txe_245 <= 1
                yield nsTimer(TXE_INACTIVE)
            else:
                if(self.dut.rxf_245.value.integer == 0 and self.dut.rx_245.value.integer == 0):
                    self.dut.txe_245 <= 1 # RX --> then NOT TX
                    yield Timer(1, units='ps')
                    yield nsTimer(RD_TO_DATA)
                    aux = self.rx_fifo.pop(0)
                    self.dut.in_out_245 <= aux #self.rx_fifo.pop(0)
                    #print "AUX = " + repr(aux)
                    yield Timer(1,units='ps')
                    if(self.dut.rx_245.value.integer == 0): yield RisingEdge(self.dut.rx_245)
                    yield nsTimer(14)
                    self.dut.rxf_245 <= 1
                    yield nsTimer(RFX_INACTIVE)
                else:
                    yield Timer(10, units='ns')


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

    __NOISE_MAX             = 8
    __SETTINGS_CHA          = 1
    __SETTINGS_CHB          = 255
    __DAC_CHA               = 127
    __DAC_CHB               = 127
    __TRIGGER_SETTINGS      = 2
    __TRIGGER_VALUE         = 150
    __NUM_SAMPLES           = 30
    __PRETRIGGER            = 10
    __ADC_CLK_DIV_CHA_L     = 1
    __ADC_CLK_DIV_CHA_H     = 0
    __ADC_CLK_DIV_CHB_L     = 1
    __ADC_CLK_DIV_CHB_H     = 0
    __N_MOVING_AVERAGE_CHA  = 0
    __N_MOVING_AVERAGE_CHB  = 0

    adc_chA = ADC(dut.chA_adc_in, dut.chA_adc_clk_o)
    adc_chB = ADC(dut.chB_adc_in, dut.chB_adc_clk_o)
    ft245 = FT245(dut)

    mySinWave_CHA = SINE_WAVE(100, 1e6, 0, 128, __NOISE_MAX)
    mySinWave_CHB = SINE_WAVE(50, 0.2e6, 0, 80, __NOISE_MAX)

    cocotb.fork( Clock(dut.clk_i,10,units='ns').start() )
    yield Reset(dut)

    cocotb.fork( adc_chA.driver() )
    cocotb.fork( adc_chB.driver() )
    cocotb.fork( ft245.driver_tx_rx() )
    cocotb.fork( adc_chA.generator(10, mySinWave_CHA.generator ) )
    cocotb.fork( adc_chB.generator(10, mySinWave_CHB.generator ) )

    # initial config
    ft245.write_reg( ADDR_SETTINGS_CHA , __SETTINGS_CHA  )
    ft245.write_reg( ADDR_SETTINGS_CHB , __SETTINGS_CHB  )
    ft245.write_reg( ADDR_DAC_CHA , __DAC_CHA  )
    ft245.write_reg( ADDR_DAC_CHB , __DAC_CHB  )
    ft245.write_reg( ADDR_TRIGGER_SETTINGS , __TRIGGER_SETTINGS  )
    ft245.write_reg( ADDR_TRIGGER_VALUE , __TRIGGER_VALUE  )
    ft245.write_reg( ADDR_NUM_SAMPLES ,  __NUM_SAMPLES  )
    ft245.write_reg( ADDR_PRETRIGGER ,  __PRETRIGGER  )
    ft245.write_reg( ADDR_ADC_CLK_DIV_CHA_L , __ADC_CLK_DIV_CHA_L  )
    ft245.write_reg( ADDR_ADC_CLK_DIV_CHA_H , __ADC_CLK_DIV_CHA_H  )
    ft245.write_reg( ADDR_ADC_CLK_DIV_CHB_L , __ADC_CLK_DIV_CHB_L  )
    ft245.write_reg( ADDR_ADC_CLK_DIV_CHB_H , __ADC_CLK_DIV_CHB_H  )
    ft245.write_reg( ADDR_N_MOVING_AVERAGE_CHA , __N_MOVING_AVERAGE_CHA  )
    ft245.write_reg( ADDR_N_MOVING_AVERAGE_CHB , __N_MOVING_AVERAGE_CHB  )
    for i in range(1000): yield RisingEdge(dut.clk_100M)

    ft245.write_reg( ADDR_REQUESTS , RQST_START_BIT )
    for i in range(100): yield RisingEdge(dut.clk_100M)
    #for i in range(10): yield RisingEdge(dut.clk_100M)
    ft245.write_reg( ADDR_REQUESTS , RQST_TRIG_BIT )

    print ("reading byte...")
    yield ft245.wait_bytes(1)
    print("available")
    i = ft245.read_data(data, 1)
    print("read")


    print ("read " + repr(i) + " bytes, data= " + str(data))
    for i in range(2000): yield RisingEdge(dut.clk_100M)
    ft245.write_reg( ADDR_REQUESTS , RQST_TRIG_BIT)
    yield ft245.wait_bytes(1)
    i = ft245.read_data(data, 1)
    print ("read " + repr(i) + " bytes, data= " + str(data))

    # send stop and channel read:
    ft245.write_reg(ADDR_REQUESTS , RQST_STOP_BIT | RQST_CHA_BIT )
    #yield ft245.wait_bytes(35, 20000)
    yield ft245.wait_bytes(30, 10000) # num_samples
    n = ft245.read_data(data, 100)
    #print ">>>>>>>>>>>>>>> HERE!"
    print "read {} bytes:".format(n)
    for i in range(len(data)):
        if i == __PRETRIGGER-1: print bcolors.OKGREEN
        print "data[{}] = {}".format(i, data[n-1-i])
        print bcolors.ENDC




class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class SINE_WAVE:
    def __init__ ( self, amp, frec, phase, offset, noise_max):
        self.amp = amp
        self.frec = frec
        self.phase = phase
        self.offset = offset
        self.noise_max = noise_max
    def generator(self, t):
        return self.offset + self.amp * sin(2*pi*self.frec * t * 1e-9 + self.phase) + randint(-self.noise_max, self.noise_max)
