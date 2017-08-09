import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

class SI_MASTER:
    def __init__ ( self, clk, rst , data, rdy):
        self.clk = clk
        self.rst = rst
        self.fifo = []
        self.data = data
        self.rdy = rdy
    
    def write(self, value):
        self.fifo.append(value)
    
    @cocotb.coroutine
    def driver(self):
        while True:
            if(len(self.fifo) > 0):
                self.data <= self.fifo.pop(0)
                self.rdy <= 1
            yield RisingEdge(self.clk)
            self.rdy <= 0
    
class SI_SLAVE:
    def __init__ ( self, clk, rst , data, rdy):
        self.clk = clk
        self.rst = rst
        self.fifo = []
        self.data = data
        self.rdy = rdy
        
    @cocotb.coroutine
    def monitor (self):
        while True:
            if(self.rdy.value.integer == 1):
                self.fifo.append(self.data.value.integer)
            yield RisingEdge(self.clk)

@cocotb.coroutine
def Reset (dut):
    dut.rst <= 0
    for i in range(10): yield RisingEdge(dut.clk)
    dut.rst <= 1
    yield RisingEdge(dut.clk)
    dut.rst <= 0
    yield RisingEdge(dut.clk)

@cocotb.test()
def test (dut):
    
    k = 1
    n = (1 << k)
    dut.k <= k
    
    fifo_test = []
    acum = 0
    
    si_master = SI_MASTER( dut.clk, dut.rst , dut.sample_in, dut.rdy_in )
    si_slave = SI_SLAVE( dut.clk, dut.rst , dut.sample_out, dut.rdy_out)

    cocotb.fork( Clock(dut.clk,10,units='ns').start() )
    yield Reset(dut)

    for i in range(100):
        aux = 10*(i+1)
        si_master.write(aux)
#        print "i%n=" + repr(i%n) + "  i=" + repr(i)
        if(i % n == 0):
            fifo_test.append(acum + aux)
            acum <= 0
        else:
            acum <= acum + aux

    cocotb.fork( si_master.driver() )
    cocotb.fork( si_slave.monitor() )
    
    for i in range(500): yield RisingEdge(dut.clk)
    
    print repr(n)
    print "-------------------- CORRECT --------------------"
    print fifo_test
    print "-------------------- READ --------------------"
    print si_slave.fifo

