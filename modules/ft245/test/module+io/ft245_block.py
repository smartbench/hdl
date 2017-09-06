
from random import randint
import cocotb
# from ft245 import Ft245
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError
from cocotb.binary import BinaryValue

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

RD_TO_DATA = 14.0;
RFX_INACTIVE = 49.0;

WR_TO_INACTIVE = 14.0;
TXE_INACTIVE = 50.0;

class SI_Master:
    def __init__ ( self, clk, rst , data, rdy, ack):
        self.clk = clk
        self.rst = rst
        self.data = data
        self.rdy = rdy
        self.ack = ack

        self.fifo = []
        self.rdy <= 0
        self.data <= 0

    def write(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def driver (self):
        myAck = 0
        while True:
            yield RisingEdge(self.clk)
            if len(self.fifo) > 0 :
                #print ("----------- READY ------------")
                self.rdy <= 1
                self.data <= self.fifo.pop(0)
                myAck = 0
                while(myAck == 0):
                    yield FallingEdge(self.clk)
                    myAck = self.ack.value.integer
                    yield RisingEdge(self.clk)
                self.rdy <= 0

class SI_Slave:
    def __init__ ( self, clk, rst , data, rdy, ack):
        self.clk = clk
        self.rst = rst
        self.data = data
        self.rdy = rdy
        self.ack = ack

        self.fifo = []
        self.ack <= 0


    @cocotb.coroutine
    def monitor ( self):
        while True:
            yield FallingEdge(self.clk)
            self.ack <= 0
            if(self.rdy.value.integer == 1):
                self.fifo.append(self.data.value.integer)
                self.ack <= 1
            yield RisingEdge(self.clk)


class FT245:
    def __init__ (self,dut):
        self.dut = dut

        self.tx_fifo = []
        self.rx_fifo = []

        self.dut.rxf_245 <= 1
        self.dut.txe_245 <= 0
        #self.dut.in_out_245 <= 0

    def write (self,val):
        self.rx_fifo.append(val)

    @cocotb.coroutine
    def tx_monitor (self):
        vec = BinaryValue()
        vec.binstr = "zzzzzzzz"
        print ("-----------------------------------------------")
        yield nsTimer(TXE_INACTIVE)
        while True:
            if True:
                self.dut.txe_245 <= 0
                if self.dut.wr_245.value.integer == 1: yield FallingEdge(self.dut.wr_245)
                self.dut.in_out_245 <= vec
                yield Timer(1, units='ps')
                #print ("{WR_245, TXE_245} = " + repr(self.dut.wr_245.value.integer) + repr(self.dut.txe_245.value.integer) )

                aux  = self.dut.in_out_245.value.integer
                #aux = 0xAA
                self.tx_fifo.append(aux)
                print ("FDTI TX: " + repr(aux))

                yield nsTimer(WR_TO_INACTIVE)
                self.dut.txe_245 <= 1
            yield nsTimer(TXE_INACTIVE)

    @cocotb.coroutine
    def rx_driver (self):
        while True:
            if(len(self.rx_fifo) > 0):
                self.dut.rxf_245 <= 0
                if(self.dut.rx_245.value.integer == 1): yield FallingEdge(self.dut.rx_245)
                yield nsTimer(RD_TO_DATA)
                #self.dut.in_out_245 <= 0
                aux = self.rx_fifo.pop(0)
                self.dut.in_out_245 <= aux #self.rx_fifo.pop(0)
                #print "-----------------------------------------------"
                #print "AUX = " + repr(aux)
                yield Timer(1,units='ps')
                #print "FDTI RX: " + repr(self.dut.in_out_245.value.integer)
                #print "-----------------------------------------------"
                if(self.dut.rx_245.value.integer == 0): yield RisingEdge(self.dut.rx_245)
                #self.dut.in_out_245 <= 0
                yield nsTimer(14)
                self.dut.rxf_245 <= 1
            yield nsTimer(RFX_INACTIVE)


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
    test_fifo_RX = []
    test_fifo_TX = []
    ft245 = FT245(dut)
    si_rx = SI_Slave( dut.clk, dut.rst, dut.rx_data_si, dut.rx_rdy_si, dut.rx_ack_si )
    si_tx = SI_Master( dut.clk, dut.rst, dut.tx_data_si, dut.tx_rdy_si, dut.tx_ack_si )
    cocotb.fork(Clock(dut.clk,10,units='ns').start())
    yield Reset(dut)
    #for i in range(100): si_tx.write(i+1)
    cocotb.fork(ft245.rx_driver() )
    cocotb.fork(ft245.tx_monitor() )
    cocotb.fork(si_rx.monitor() )
    cocotb.fork(si_tx.driver() )
    for i in range(10): yield RisingEdge(dut.clk)
    for i in range(50):
        ft245.write(i+1)
        test_fifo_RX.append(i+1)
    for i in range(10*130): yield RisingEdge(dut.clk)
    for i in range(50):
        ft245.write(i+51)
        test_fifo_RX.append(i+51)
    for i in range(10*130): yield RisingEdge(dut.clk)

    #if (ft245.tx_fifo != [i for i in range(150)]):
    #    raise TestFailure("Simple Interface data != FT245 data (TX)")
#
    if ( si_rx.fifo != [ i+1 for i in range(100)]):
        raise TestFailure("Simple Interface data != FT245 data (RX)")

    print "-----------> EEEE-XITO (RX) <------------"

    for i in range(20):
        aux = (1 << (i%8))# % 256
        si_tx.write(aux)
        test_fifo_TX.append(aux)

    for i in range(200): yield RisingEdge(dut.clk)

    print ("Len(test) = " + repr(len(test_fifo_TX)) + " ### Len(tx) = " + repr(len(ft245.tx_fifo)))
    if (len(test_fifo_TX) != len(ft245.tx_fifo) ):
        raise TestFailure("DIFFERENT SIZE")
    for i in range(len(test_fifo_TX)):
        if ft245.tx_fifo[i] != test_fifo_TX[i]:
            print "ft245.tx_fifo[{}]={}\ttest_fifo_TX[{}]={}".format(i,ft245.tx_fifo[i],i,test_fifo_TX[i])
            # print '%d %d' % (1, 2)
            # print '{} {}'.format(1, 2)
            raise TestFailure("Simple Interface data != FT245 data (TX)")

    print "-----------> EEEE-XITO (TX) <------------"
