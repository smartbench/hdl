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
    def __init__ (self, clk, data, rdy, eof, ack):
        self.clk = clk
        self.data = data
        self.rdy = rdy
        self.eof = eof
        self.ack = ack

        self.fifo = []
        self.data <= 0
        self.rdy <= 0
        self.eof <= 1

    def write(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def raise_rdy(self):
        if(len(self.fifo) > 0):
            self.data <= self.fifo.pop(0)
            self.rdy <= 1
            self.eof <= 0
        else:
            self.rdy <= 0
            self.eof <= 1
        yield RisingEdge(self.clk)


    @cocotb.coroutine
    def data_source (self):
        while True:
            if(self.ack.value.integer == 1):
                if(len(self.fifo) > 0):
                    self.data <= self.fifo.pop(0)
                else:
                    self.eof <= 1
                    self.rdy <= 0
            yield RisingEdge(self.clk)
            # add later: random delay between 0 and 2 clocks
            #i = randint(0,2)
            #while(i > 0):
            #    yield RisingEdge(self.clk)
            #    i = i - 1

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
            yield Timer(1,'ps')
            self.tx_ack <= 0
            if(self.tx_rdy.value.integer == 1):
                self.tx_ack <= 1
                self.fifo.append(self.tx_data.value.integer)
            yield RisingEdge(self.clk)

            # add later: random delay between 0 and 2 clocks
            #i = randint(0,2)
            #while(i > 0):
            #    yield RisingEdge(self.clk)
            #    i = i - 1

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
    samples_ch1 = 30
    samples_ch2 = 24

    #dut.rst <= 1

    src_ch1 = SOURCE(dut.clk, dut.ch1_data, dut.ch1_rdy, dut.ch1_eof, dut.ch1_ack)
    src_ch2 = SOURCE(dut.clk, dut.ch2_data, dut.ch2_rdy, dut.ch2_eof, dut.ch2_ack)
    src_trig = SOURCE(dut.clk, dut.trig_data, dut.trig_rdy, dut.trig_eof, dut.trig_ack)

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

    for i in range(10): yield RisingEdge(dut.clk)
    yield src_ch1.raise_rdy()
    #src_ch1.raise_rdy()
    for i in range(20): yield RisingEdge(dut.clk)
    yield src_ch2.raise_rdy()


    # Now wait for the data to be sent
    for i in range(50): yield RisingEdge(dut.clk)

    # Start of the test
    err = 0
    # Error checking - CH1
    print "-------------------------------------"
    print "LEN_FIFO_CH1=" + repr(len(src_ch1.fifo))
    print "LEN_FIFO_TX=" + repr(len(ft245.fifo))
    print "TX\t||\tCH1"
    for i in range (len(fifo_test_ch1)):
        if(len(ft245.fifo) == 0):
            a = "EMPTY"
            err = 1
        else:
            a = ft245.fifo.pop(0)   #ft245.fifo[i]
        b = fifo_test_ch1[i]
        if (a == b):
            print (repr(a) + '\t==\t' + repr(b) )
        else:
	        print (repr(a) + '\t!=\t' + repr(b) )
	        err = 1

    # Error checking - CH2
    print "-------------------------------------"
    print "LEN_FIFO_CH2=" + repr(len(src_ch2.fifo))
    print "LEN_FIFO_TX: " + repr(len(ft245.fifo))
    print "TX\t||\tCH2"
    for i in range (len(fifo_test_ch2)):
        if(len(ft245.fifo) == 0):
            a = "EMPTY"
            err = 1
        else:
            a = ft245.fifo.pop(0)   #ft245.fifo[i]
        b = fifo_test_ch2[i]
        if (a == b):
            print (repr(a) + '\t==\t' + repr(b) )
        else:
	        print (repr(a) + '\t!=\t' + repr(b) )
	        err = 1

    print "-------------------------------------"

    if(err==1):
        raise TestFailure("Error, reading isn't equal to writing")
    else:
        print "______________________________"
        print " The CHAAAAAMPIONSHIP-POINT !!"
        print "______________________________"
        print ""
