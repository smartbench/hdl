
from random import randint
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

from math import pi, sin

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
            self.out <= int(self.amp * sin(2*pi*self.freq*self.t*1e-9))
            self.out_ena <= 1
            yield RisingEdge(self.clk)
            self.out_ena <= 0
            for i in range(3): yield RisingEdge(self.clk)
            self.t = self.t + 4 * 10

class Detector:
    def __init__ ( self, clk, rst, in_ena, triggered, dut):
        self.clk = clk
        self.rst = rst
        self.in_ena = in_ena
        self.triggered = triggered
        self.dut = dut

        self.sample = 0
        self.trig_sample = 0

    @cocotb.coroutine
    def monitor (self):
        while True:
            yield RisingEdge(self.clk)
            if(self.in_ena == 1): self.sample = self.sample + 1
            if(self.triggered == 1):
                self.trig_sample = self.sample
                self.dut._log.info("Triggered! Sample= %s" % self.sample)

@cocotb.coroutine
def Reset (dut):
    dut.reset <= 0
    for i in range(10): yield RisingEdge(dut.clk)
    dut.reset <= 1
    yield RisingEdge(dut.clk)
    dut.reset <= 0
    yield RisingEdge(dut.clk)

@cocotb.test()
def test (dut):
    amp = 100
    freq = 1000000
    dut.trigger_value <= 50
    dut.trigger_edge <= 0
    generator = Generator(dut.clk, dut.reset, dut.input_sample, dut.in_ena, freq, amp)
    detector = Detector(dut.clk, dut.reset, dut.out_ena, dut.triggered, dut)
    cocotb.fork(Clock(dut.clk,10,units='ns').start())
    yield Reset(dut)
    cocotb.fork(detector.monitor())
    cocotb.fork(generator.run())
    for i in range(200): yield RisingEdge(dut.clk)
