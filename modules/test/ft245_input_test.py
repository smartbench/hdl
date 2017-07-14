
import cocotb
# from ft245 import Ft245
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge

class Ft245:
    def __init__ (self,dut):
        self.dut = dut
        self.fifo = []
        self.dut.rxf_245 <= 1
        self.dut.in_245 <= 0

    def write (self,val):
        self.fifo.append(val)
        self.dut.rxf_245 <= 0

    @cocotb.coroutine
    def rx_driver ( val ):
        yield FallingEdge(rx_245)
        yield Timer(30)
        if rx_245.value.integer == 1:
            raise TestFailure(


@cocotb.test()
def test (dut):
    cocotb.fork(Clock(dut.clk,100).start())
    yield Timer(100000,units='ns')
