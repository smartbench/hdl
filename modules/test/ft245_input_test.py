import cocotb
# from ft245 import Ft245
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')


class Ft245:
    def __init__ (self,dut):
        self.dut = dut
        self.fifo = []
        self.rxing = False
        self.dut.rxf_245 <= 1
        self.dut.in_245 <= 0

    def write (self,val):
        self.fifo.append(val)
        if self.rxing == False:
            self.dut.rxf_245 <= 0

    @cocotb.coroutine
    def rx_driver (self):
        while True: 
            self.rxing = False
            yield FallingEdge(self.dut.rx_245)
            self.rxing = True
            if self.dut.rxf_245.value.integer == 1:
                raise TestFailure("FT245 Reading failure: There is not value in the fifo")
            yield nsTimer(14)
            self.dut.in_245 = self.fifo.pop(0)
            yield nsTimer(16)
            if self.dut.rx_245.value.integer == 1:
                raise TestFailure("FT245 Timming Failure: You must wait at least 30ns ")
            yield RisingEdge(self.dut.rx_245)
            yield nsTimer(14)
            self.dut.rxf_245 <= 1
            yield nsTimer(49)
            self.dut.rxf_245 <=  int(len(self.fifo) == 0)
            if self.dut.rx_245.value.integer == 0:
                raise TestFailure("FT245 Timming Failure: Fifo is inactive ")



@cocotb.test()
def test (dut):
    ft245 = Ft245(dut)
    cocotb.fork(Clock(dut.clk,10,units='ns').start())
    cocotb.fork(ft245.rx_driver() )
    for i in range(10): yield RisingEdge(dut.clk)
    ft245.write(255)
    for i in range(10): yield RisingEdge(dut.clk)
