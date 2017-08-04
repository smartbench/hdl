''' toDo:
    * Read and write at the same time -> OK
    * Write the full length and read back -> OK
    * Instantiate a block ram with WR_DATA_WIDTH=8bits and RD_DATA_WIDTH=16bits
    to make multiple reads in one clock

    * Get the interface right
'''

from random import randint
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError


@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')


class CHANNEL:
    def __init__ (self, clk, din, rdy, ack):
        self.clk = clk
        self.din = din
        self.rdy = rdy
        self.ack = ack
        self.fifo = []

        self.din <= 0
        self.rdy <= 0

    def write(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def generator (self):
        while True:
            yield RisingEdge(self.clk)
            if len(self.fifo) > 0 :
                self.din <= self.fifo.pop(0)
                self.rdy <= 1
            yield RisingEdge(self.clk)
            self.rdy <= 0
            self.din <= 0
            for i in range(2): yield RisingEdge(self.clk)


class TX_PROTOCOL:
    def __init__ (self, clk, dout, read_enable, eof, rqst):
        self.clk = clk
        self.dout = dout
        self.read_enable = read_enable
        self.eof = eof
        self.rqst = rqst
        self.fifo = []

        self.read_enable <= 0
        self.rqst <= 0

    @cocotb.coroutine
    def request_data (self):
        self.read_enable <= 0
        self.rqst <= 1
        yield RisingEdge(self.clk)
        self.rqst <= 0
        yield RisingEdge(self.clk)
        while (self.eof.value.integer == 0):
            self.fifo.append(self.dout.value)
            self.read_enable <= 1
            yield RisingEdge(self.clk)
            self.read_enable <= 0
            if(self.eof.value.integer == 1): break
            for i in range(3): yield RisingEdge(self.clk) # simulando demora en lectura

@cocotb.test()
def test (dut):
    fifo_test = []
    channel = CHANNEL(dut.clk, dut.din, dut.si_rdy_adc, dut.si_ack_adc)
    tx_protocol = TX_PROTOCOL(dut.clk, dut.dout, dut.rd_en, dut.EOF, dut.rqst_buff)
    dut.n_samples <= 100
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    for i in range(128):
        #aux = randint(0,100)
        aux = (1+i) % 256
        fifo_test.append(aux)
        channel.write(aux)
    cocotb.fork(channel.generator() )
    cocotb.fork(tx_protocol.request_data() )
    yield RisingEdge(dut.clk)
    for i in range (1024): yield RisingEdge(dut.clk)

    err = 0
    for i in range (len(tx_protocol.fifo)):
        a = tx_protocol.fifo[i].value
        b = fifo_test[127-i]
        if (a == b):
            print (repr(a) + ' == ' + repr(b) )
        else:
	        print (repr(a) + ' != ' + repr(b) )
	        err = 1

    if(err==1): raise TestFailure("Error, reading isn't equal to writing")
