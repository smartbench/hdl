import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

class Adc:
    def __init__ ( self, dut ):
        self.dut = dut
        self.fifo = []
        self.dut.adc_input <= 0

    def takeSample(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def driver (self):
        while True:
            yield RisingEdge(self.dut.adc_clk_o)
            yield Timer(1,units='ps')

            nsTimer(10)
            self.dut.adc_input <= 0 # invalid data here
            nsTimer(9.5)
            if ( len(self.fifo) > 0 ):
                self.dut.adc_input = self.fifo.pop(0)
                #print 'poping' # Pooping? there is no more toilet paper!
            else:
                self.dut.adc_input <= 0

class SI_REG_Master:
    def __init__ (self, clk, rst, reg_si_data, reg_si_addr, reg_si_rdy):
        self.rst = rst
        self.clk = clk
        self.reg_si_data = reg_si_data
        self.reg_si_addr = reg_si_addr
        self.reg_si_rdy = reg_si_rdy
        self.fifo_data = []
        self.fifo_addr = []

        self.reg_si_addr <= 0
        self.reg_si_data <= 0
        self.reg_si_rdy <= 0

    def writeReg (self, addr, data):
        self.fifo_addr.append(addr)
        self.fifo_data.append(data)

    @cocotb.coroutine
    def driver (self):
        while True:
            yield RisingEdge(self.clk)
            yield Timer(1,units='ps')

            if (len(self.fifo_data)>0):
                print "HOLAAAAAAAAAA"
                self.reg_si_data <= self.fifo_data.pop(0)
                self.reg_si_addr <= self.fifo_addr.pop(0)
                self.reg_si_rdy <= 1

                yield RisingEdge(self.clk)
                yield Timer(1,units='ps')

                self.reg_si_rdy <= 0

class TX_PROTOCOL:
    def __init__ (self, clk, data_out, data_rdy, data_eof, data_ack, rqst, wr_en):
        self.clk = clk
        self.data_out = data_out
        self.data_rdy = data_rdy
        self.data_eof = data_eof
        self.data_ack = data_ack
        self.rqst = rqst
        self.fifo = []
        self.wr_en = wr_en

        self.data_ack <= 0
        self.rqst <= 0
        self.wr_en <= 0

    @cocotb.coroutine
    def request_data (self):
        self.data_ack <= 0
        self.wr_en <= 0
        self.rqst <= 1
        yield RisingEdge(self.clk)
        self.rqst <= 0
        yield RisingEdge(self.clk)
        if (self.data_rdy.value.integer == 0): yield RisingEdge(self.data_rdy)
        yield FallingEdge(self.clk)
        while (self.data_eof.value.integer == 0):
            if(self.data_rdy.value.integer == 1):
                self.fifo.append(self.data_out.value.integer)
                self.data_ack <= 1
            yield RisingEdge(self.clk)
            self.data_ack <= 0
            for i in range(3):
                if(self.data_eof.value.integer == 1): break
                yield RisingEdge(self.clk) # simulando demora en lectura
            yield FallingEdge(self.clk)

@cocotb.coroutine
def Reset (dut):
    dut.rst <= 0
    for i in range(10):
        yield RisingEdge(dut.clk)
        yield Timer(1,units='ps')
    dut.rst <= 1
    yield RisingEdge(dut.clk)
    yield Timer(1,units='ps')
    dut.rst <= 0
    yield RisingEdge(dut.clk)
    yield Timer(1,units='ps')

@cocotb.test()
def channel_block (dut):

    #REG_ADDR_CH_SETTINGS = 1
    #REG_ADDR_DAC_VALUE = 3
    REG_ADDR_ADC_DF_L = 9
    REG_ADDR_ADC_DF_H = 10
    REG_ADDR_MOV_AVE_K = 11

    DF = 2
    K = 1


    adc = Adc(dut)
    si_reg = SI_REG_Master (dut.clk, dut.rst, dut.register_data, dut.register_addr, dut.register_rdy)
    tx_protocol = TX_PROTOCOL(dut.clk, dut.tx_data, dut.tx_rdy, dut.tx_eof, dut.tx_ack, dut.rqst_data, dut.we)

    #print 'Taking samples'
    for i in range(100):
        aux = (i+1)*10
        adc.takeSample(aux)

    si_reg.writeReg( REG_ADDR_ADC_DF_L , DF % (256*256) )
    si_reg.writeReg( REG_ADDR_ADC_DF_H , (DF >> 16) % (256*256) )
    si_reg.writeReg( REG_ADDR_MOV_AVE_K , K )

    cocotb.fork( Clock(dut.clk,10,units='ns').start() )

    dut.tx_ack <= 1
    dut.we <= 0
    dut.num_samples <= 100
    yield Reset(dut)

    dut.we <= 1

    cocotb.fork( adc.driver() )
    cocotb.fork ( si_reg.driver() )

    for i in range(100):
        yield RisingEdge(dut.adc_clk_o)
        yield Timer(1,units='ps')

    dut.we <= 0
    cocotb.fork( tx_protocol.request_data() )

    for i in range(53):
        print i
        yield RisingEdge(dut.clk)
        yield Timer(1,units='ps')
