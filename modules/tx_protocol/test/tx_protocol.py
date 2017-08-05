''' toDo:
    * everything!!
    NOTE: THIS WAS DONE FOR A DIFFERENT tx_protocol.v!!
        Modify accordingly!!
'''

from random import randint
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError


@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')


class SOURCE:
    def __init__ (self, clk, data, rqst, eof, ack):
        self.clk = clk
        self.data = data
        self.rqst = rqst
        self.eof = eof
        self.ack = ack
        self.fifo = []

        self.data <= 0
        self.eof <= 0

    def write(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def data_source (self):
        while True:
            while(self.rqst == 0): yield RisingEdge(self.clk)
            yield RisingEdge(self.clk)
            while (len(self.fifo) > 0):
                self.data <= self.fifo.pop(0)
                yield RisingEdge(self.clk)
                while(self.ack.value.integer == 0): yield RisingEdge(self.clk)
            self.eof <= 1
            yield RisingEdge(self.clk)
            self.eof <= 0
            yield RisingEdge(self.clk)


class FT245:
    def __init__ (self, clk, tx_data, tx_rdy, tx_ack):
        self.clk = clk
        self.tx_data = tx_data
        self.tx_rdy = tx_rdy
        self.tx_ack = tx_ack

        self.fifo = []
        self.tx_ack <= 0

    @cocotb.coroutine
    def tx_driver (self):
        while True:
            while(self.tx_rdy == 0):
                yield RisingEdge(self.clk)
            i = randint(0,2)
            # random delay between 0 and 2 clocks
            while(i > 0):
                yield RisingEdge(self.clk)
                i = i - 1
            self.fifo.append(self.tx_data.value.integer)
            self.tx_ack <= 1
            yield RisingEdge(self.clk)
            self.tx_ack <= 0

@cocotb.coroutine
def Reset (dut):
    dut.rst <= 1
    for i in range(10): yield RisingEdge(dut.clk)
    dut.rst <= 0
    yield RisingEdge(dut.clk)


@cocotb.test()
def test (dut):
    fifo_test_ch1 = []
    fifo_test_ch2 = []
    samples_ch1 = 100
    samples_ch2 = 24

    dut.rqst_rdy <= 0
    dut.rqst_id <= 0
    dut.rst <= 1

    src_ch1 = SOURCE(dut.clk, dut.ch1_data, dut.ch1_rqst, dut.ch1_eof, dut.ack)
    src_ch2 = SOURCE(dut.clk, dut.ch2_data, dut.ch2_rqst, dut.ch2_eof, dut.ack)
    src_trig = SOURCE(dut.clk, dut.trig_data, dut.trig_rqst, dut.trig_eof, dut.ack)

    ft245 = FT245(dut.clk, dut.tx_data, dut.tx_rdy, dut.tx_ack)

    cocotb.fork(Clock(dut.clk, 10, units='ns').start())

    for i in range(samples_ch1):
        #aux = randint(0,100)
        aux = (1+i) % 256
        fifo_test_ch1.append(aux)
        src_ch1.write(aux)

    for i in range(samples_ch2):
        #aux = randint(0,100)
        aux = (1+i) % 256
        fifo_test_ch2.append(aux)
        src_ch2.write(aux)

    print "-------------------------------------"
    print "FIFO_CH1_LEN=" + repr(len(src_ch1.fifo))
    print "FIFO_CH2_LEN=" + repr(len(src_ch2.fifo))

    yield Reset(dut)

    cocotb.fork(ft245.tx_driver() )
    cocotb.fork(src_ch1.data_source() )
    cocotb.fork(src_ch2.data_source() )

    yield RisingEdge(dut.clk)

    # Start of the test
    err = 0

    # Testing source: ch1
    ft245.fifo = []
    dut.rqst_id <= 1
    dut.rqst_rdy <= 1
    yield RisingEdge(dut.clk)
    dut.rqst_rdy <= 0
    # Now wait for the data to be sent
    for i in range (300): yield RisingEdge(dut.clk)

    # Error checking
    print "-------------------------------------"
    print "FIFO_CH1_LEN=" + repr(len(src_ch1.fifo))
    print "CH1 - FIFO_LEN=" + repr(len(ft245.fifo))
    for i in range (len(ft245.fifo)):
        a = ft245.fifo[i]
        b = fifo_test_ch1[i]
        if (a == b):
            print (repr(a) + ' == ' + repr(b) )
        else:
	        print (repr(a) + ' != ' + repr(b) )
	        err = 1

    # Testing source: ch2
    ft245.fifo = []
    dut.rqst_id <= 2
    dut.rqst_rdy <= 1
    yield RisingEdge(dut.clk)
    dut.rqst_rdy <= 0
    # Now wait for the data to be sent
    for i in range (300): yield RisingEdge(dut.clk)

    # Error checking
    print "-------------------------------------"
    print "FIFO_CH2_LEN=" + repr(len(src_ch2.fifo))
    print "CH2 - tx length: " + repr(len(ft245.fifo))
    for i in range (len(ft245.fifo)):
        a = ft245.fifo[i]
        b = fifo_test_ch2[i]
        if (a == b):
            print (repr(a) + ' == ' + repr(b) )
        else:
	        print (repr(a) + ' != ' + repr(b) )
	        err = 1

    print "-------------------------------------"

    if(err==1):
        raise TestFailure("Error, reading isn't equal to writing")
    else:
        print "______________________________"
        print " The CHAAAAAMPIONSHIP-POINT !!"
        print "______________________________"
        print ""
