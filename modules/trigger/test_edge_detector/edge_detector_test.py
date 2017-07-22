
from random import randint
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

from math import pi, sin
from ctypes import c_ubyte,c_int

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')


class Generator:
    def __init__ ( self, clk, rst, out, out_ena, freq, amp):
        self.clk = clk
        self.rst = rst
        self.out = out
        self.out_ena = out_ena
        self.freq = freq
        self.amp = amp  # -128 to 127

        self.out <= int(0)
        self.out_ena <= 0
        self.t = 0

    @cocotb.coroutine
    def run(self):
        while True:
            self.out <= int(128 + self.amp * sin(2*pi*self.freq*self.t*1e-9))
            self.out_ena <= 1
            yield RisingEdge(self.clk)
            self.out_ena <= 0
            for i in range(3): yield RisingEdge(self.clk)
            self.t = self.t + 4 * 10

class Detector:
    def __init__ ( self, clk, rst, in_ena, triggered):
        self.clk = clk
        self.rst = rst
        self.in_ena = in_ena
        self.triggered = triggered

        self.sample = 0
        self.trig_sample = 0

    @cocotb.coroutine
    def monitor (self):
        while True:
            yield RisingEdge(self.clk)
            if(self.in_ena == 1): self.sample = self.sample + 1
            if(self.triggered == 1):
                self.trig_sample = self.sample
                print("sample = %s" % self.trig_sample)

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
    amp = 100
    freq = 1000000
    dut.trigger_value <= 50
    #dut.edge_type <= 0
    generator = Generator(dut.clk, dut.rst, dut.input_sample, dut.in_ena, freq, amp)
    detector = Detector(dut.clk, dut.rst, dut.in_ena, dut.triggered)
    cocotb.fork(Clock(dut.clk,10,units='ns').start())
    yield Reset(dut)
    cocotb.fork(detector.monitor())
    cocotb.fork(generator.run())
    for i in range(200): yield RisingEdge(dut.clk)
