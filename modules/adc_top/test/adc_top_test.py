import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

class SI_Slave:
    def __init__ ( self, clk, rst , data, rdy):
        self.data = data
        self.rdy = rdy
        self.fifo = []
        self.clk = clk
        self.rst = rst

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

class Adc:
    def __init__ ( self, dut ):
        self.dut = dut
        self.fifo = []
        self.dut.adc_data <= 0
        self.dut.adc_si_data <= 0 # Output of Moving average

    def takeSample(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def driver (self):
        while True:
            yield RisingEdge(self.dut.clk_o)
            nsTimer(10)
            self.dut.adc_data <= 0 # invalid data here
            nsTimer(9.5)
            if ( len(self.fifo) > 0 ):
                self.dut.adc_data = self.fifo.pop(0)
                #print 'poping'
            else:
                self.dut.adc_data = 0

class SI_REG_Master:
    def __init__ (self, clk, reset, reg_si_data, reg_si_addr, reg_si_rdy, reg_si_ack):
        self.reset = reset
        self.clk = clk
        self.reg_si_data = reg_si_data
        self.reg_si_addr = reg_si_addr
        self.reg_si_rdy = reg_si_rdy
        self.reg_si_ack = reg_si_ack
        self.fifo = []

    def writeReg (self, data, addr):
        self.fifo.append((data, addr))

    @cocotb.coroutine
    def driver (self):
        while True:
            yield RisingEdge(self.clk)
            if (len(self.fifo)>0):
                print "HOLAAAAAAAAAA"
                aux = self.fifo.pop(0)
                self.reg_si_data <= aux[0]
                self.reg_si_addr <= aux[1]
                self.reg_si_rdy <= 1
                while self.reg_si_ack.value.integer != 1 : yield RisingEdge(self.clk)
                self.reg_si_rdy <= 0


@cocotb.coroutine
def Reset (dut):
    dut.reset <= 0
    for i in range(10): yield RisingEdge(dut.clk_i)
    dut.reset <= 1
    yield RisingEdge(dut.clk_i)
    dut.reset <= 0
    yield RisingEdge(dut.clk_i)

@cocotb.test()
def adc_top_test (dut):
    adc = Adc(dut)
    si_adc = SI_Slave( dut.clk_i, dut.reset, dut.adc_si_data, dut.adc_si_rdy)
    si_reg = SI_REG_Master (dut.clk_i, dut.reset, dut.reg_si_data, dut.reg_si_addr, dut.reg_si_rdy, dut.reg_si_ack)
    cocotb.fork( Clock(dut.clk_i,10,units='ns').start() )
    yield Reset(dut)

    #print 'Taking samples'
    # for i in range(302): adc.takeSample(i)
    # cocotb.fork( adc.driver() )
    # cocotb.fork( si_adc.monitor() )
    #
    # for i in range(302): yield RisingEdge(dut.clk_o)

    #parameter REG_MA_DF_ADDR = 2
    si_reg.writeReg(1,2)
    # print "HOLA"
    # aux = si_reg.fifo[0]
    # print aux[0]
    # print aux[1]
    # print "CHAU"
    cocotb.fork ( si_reg.driver() )
    for i in range(20): yield RisingEdge(dut.clk_i)




    #
    # if( si_adc.fifo != [i for i in range(150)]):
    #     print "Houston, we have a problem here ..."
    #     print si_adc.fifo
    #     raise TestFailure("Simple Interface data != ADC samples")

    # dut.decimation_factor <= 1
    #
    # for i in range(150): yield RisingEdge(dut.clk_o)
    #
    # if( si_adc.fifo != [i%256 for i in range(300)]):
    #     print "Houston, we have a problem here ... N2"
    #     print si_adc.fifo
    #     raise TestFailure("Simple Interface data != ADC samples")
