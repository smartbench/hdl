
from random import randint
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

from math import pi, sin

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')


class RAM_Controller:
    def __init__ (self, clk, we, ch1, ch2):
        self.clk = clk
        self.we = we
        self.ch1 = ch1
        self.ch2 = ch2
        self.fifo_ch1 = []
        self.fifo_ch2 = []

    def write(self,input_1,input_2):
        self.fifo_ch1.append(input_1)
        self.fifo_ch2.append(input_2)

    @cocotb.coroutine
    def run(self):
        while True:
            if(self.we):
                self.write(self.ch1,self.ch2)
            yield RisingEdge(self.clk)

class ADC:
    def __init__ (self, clk, ch1=0, ch2=0, in_ena=0):
        self.clk = clk
        self.ch1 = ch1
        self.ch2 = ch2
        self.in_ena = in_ena
        self.fifo_ch1 = []
        self.fifo_ch2 = []

        self.ch1 <= 0
        self.ch2 <= 0
        self.in_ena <= 0

    def write(self,input_1,input_2):
        self.fifo_ch1.append(input_1)
        self.fifo_ch2.append(input_2)

    @cocotb.coroutine
    def sampling (self):
        while True:
            if (len(self.fifo_ch1) > 0 and len(self.fifo_ch2) > 0):
                self.ch1 <= self.fifo_ch1.pop(0)
                self.ch2 <= self.fifo_ch2.pop(0)
                self.in_ena <= 1
            yield RisingEdge(self.clk)
            self.in_ena <= 0
            for i in range(3): yield RisingEdge(self.clk)


@cocotb.coroutine
def Start(dut):
    dut.start <= 1
    yield RisingEdge(dut.clk)
    dut.start <= 0
    yield RisingEdge(dut.clk)

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
    dut.num_samples <= 16       # number of samples
    dut.pre_trigger <= 8        # number of samples before trigger
    dut.trigger_source <= 1     # CH1
    dut.trigger_conf <= 0       # single
    dut.edge_type <= 0          # positive edge
    dut.trigger_value <= 170    # trigger value

    ram = RAM_Controller(dut.clk, dut.write_enable, dut.ch1_out, dut.ch2_out)
    adc = ADC(dut.clk, dut.ch1_in, dut.ch2_in, dut.in_ena)

    cocotb.fork(Clock(dut.clk,10,units='ns').start())
    yield Reset(dut)

    for t in range(200):
        x1 = 128 + int(100 * sin(2*pi*1e6*t*20e-9))
        x2 = 128 - int(050 * sin(2*pi*1e6*t*20e-9))
        adc.write(x1, x2)

    cocotb.fork(ram.run())
    cocotb.fork(adc.sampling())

    yield Start(dut)

    for i in range(1000): yield RisingEdge(dut.clk)
