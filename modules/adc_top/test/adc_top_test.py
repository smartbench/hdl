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
        self.dut.adc_data_i <= 0
#        self.dut.adc_si_data <= 0 # Output of Moving average

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
                #print 'poping'
            else:
                self.dut.adc_data_i <= 0

class SI_REG_Master:
    def __init__ (self, clk, rst, reg_si_data, reg_si_addr, reg_si_rdy):
        self.rst = rst
        self.clk = clk
        self.reg_si_data = reg_si_data
        self.reg_si_addr = reg_si_addr
        self.reg_si_rdy = reg_si_rdy
        self.fifo_data = []
        self.fifo_addr = []
        
        self.reg_si_data <= 0
        self.reg_si_data <= 0
        self.reg_si_rdy <= 0

    def writeReg (self, addr, data):
        self.fifo_addr.append(addr)
        self.fifo_data.append(data)

    @cocotb.coroutine
    def driver (self):
        while True:
            yield RisingEdge(self.clk)
            if (len(self.fifo_data)>0):
                print "HOLAAAAAAAAAA"
                self.reg_si_data <= self.fifo_data.pop(0)
                self.reg_si_addr <= self.fifo_addr.pop(0)
                self.reg_si_rdy <= 1
                yield RisingEdge(self.clk)
                self.reg_si_rdy <= 0


@cocotb.coroutine
def Reset (dut):
    dut.rst <= 0
    for i in range(10): yield RisingEdge(dut.clk_i)
    dut.rst <= 1
    yield RisingEdge(dut.clk_i)
    dut.rst <= 0
    yield RisingEdge(dut.clk_i)

@cocotb.test()
def adc_top_test (dut):
    adc = Adc(dut)
    si_slave = SI_Slave( dut.clk_i, dut.rst, dut.si_data_o, dut.si_rdy_o)
    si_reg = SI_REG_Master (dut.clk_i, dut.rst, dut.reg_si_data, dut.reg_si_addr, dut.reg_si_rdy)
    
    #print 'Taking samples'
    for i in range(100): adc.takeSample(i)

    #parameter REG_ADDR_ADC_DF_L = 0,
    si_reg.writeReg(0,1)
    #parameter REG_ADDR_ADC_DF_H = 1,
    si_reg.writeReg(1,0)
    #parameter REG_ADDR_MOV_AVE_K = 2
    si_reg.writeReg(2,0)
    
    cocotb.fork( Clock(dut.clk_i,10,units='ns').start() )
    yield Reset(dut)

    cocotb.fork( adc.driver() )
    cocotb.fork( si_slave.monitor() )
    cocotb.fork ( si_reg.driver() )
    for i in range(1000): yield RisingEdge(dut.clk_i)
#    for i in range(302): yield RisingEdge(dut.clk_o)




    #
    # if( si_slave.fifo != [i for i in range(150)]):
    #     print "Houston, we have a problem here ..."
    #     print si_slave.fifo
    #     raise TestFailure("Simple Interface data != ADC samples")

    # dut.decimation_factor <= 1
    #
    # for i in range(150): yield RisingEdge(dut.clk_o)
    #
    # if( si_slave.fifo != [i%256 for i in range(300)]):
    #     print "Houston, we have a problem here ... N2"
    #     print si_slave.fifo
    #     raise TestFailure("Simple Interface data != ADC samples")
