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

TX_FIFO_MAX = 100

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
    def driver_tx_rx (self):
        highZ = BinaryValue()
        highZ.binstr = "zzzzzzzz"
        while True:
            if(len(self.tx_fifo) < TX_FIFO_MAX): self.dut.txe_245 <= 0
            else: self.dut.txe_245 <= 1

            if(len(self.rx_fifo) > 0): self.dut.rxf_245 <= 0
            else: self.dut.rxf_245 <= 1

            if(self.dut.txe_245.value.integer == 0 and self.dut.wr_245.value.integer == 0):
                self.dut.rxf_245 <= 1 # TX --> then NOT RX
                # start tx sequence
                self.dut.in_out_245 <= highZ
                yield Timer(1, units='ps')
                self.tx_fifo.append(self.dut.in_out_245.value.integer)
                #print ("FDTI TX: " + repr(self.dut.in_out_245.value.integer))
                yield nsTimer(14+WR_TO_INACTIVE) #T6+...
                if (self.dut.wr_245.value.integer == 0): yield RisingEdge(self.dut.wr_245)
                self.dut.txe_245 <= 1
                yield nsTimer(TXE_INACTIVE)
            else:
                if(self.dut.rxf_245.value.integer == 0 and self.dut.rx_245.value.integer == 0):
                    self.dut.txe_245 <= 1 # RX --> then NOT TX
                    yield Timer(1, units='ps')
                    yield nsTimer(RD_TO_DATA)
                    aux = self.rx_fifo.pop(0)
                    self.dut.in_out_245 <= aux #self.rx_fifo.pop(0)
                    #print "AUX = " + repr(aux)
                    yield Timer(1,units='ps')
                    if(self.dut.rx_245.value.integer == 0): yield RisingEdge(self.dut.rx_245)
                    yield nsTimer(14)
                    self.dut.rxf_245 <= 1
                    yield nsTimer(RFX_INACTIVE)
                else:
                    yield Timer(10, units='ns')


@cocotb.coroutine
def Reset (dut):
    dut.rst_i <= 0
    for i in range(10): yield RisingEdge(dut.clk_i)
    dut.rst_i <= 1
    yield RisingEdge(dut.clk_i)
    dut.rst_i <= 0
    yield RisingEdge(dut.clk_i)


@cocotb.test()
def test (dut):
    test_fifo_RX = []
    test_fifo_TX = []
    ft245 = FT245(dut)

    cocotb.fork(Clock(dut.clk_i,10,units='ns').start())
    yield Reset(dut)
    #for i in range(100): si_tx.write(i+1)
    #cocotb.fork(ft245.rx_driver() )
    #cocotb.fork(ft245.tx_monitor() )
    cocotb.fork(ft245.driver_tx_rx())

    for i in range(10): yield RisingEdge(dut.clk_i)
    for i in range(50):
        ft245.write(i+1)
        test_fifo_RX.append(i+1)
    for i in range(10*130): yield RisingEdge(dut.clk_i)
    for i in range(50):
        ft245.write(i+51)
        test_fifo_RX.append(i+51)
    for i in range(20*130): yield RisingEdge(dut.clk_i)

    #if (ft245.tx_fifo != [i for i in range(150)]):
    #    raise TestFailure("Simple Interface data != FT245 data (TX)")
#
    if ( ft245.tx_fifo != [ test_fifo_RX[i] for i in range(100)]):
        print("test_fifo_RX = {}".format(test_fifo_RX))
        print("ft245.tx_fifo = {}".format(ft245.tx_fifo))
        raise TestFailure("TX fifo != test fifo")

    print "-----------> EEEE-XITO (RX) <------------"

    print ("Len(RX) = " + repr(len(test_fifo_RX)) + " ### Len(TX) = " + repr(len(ft245.tx_fifo)))
    if (len(test_fifo_RX) != len(ft245.tx_fifo) ):
        raise TestFailure("DIFFERENT SIZE")
    for i in range(len(ft245.tx_fifo)):
        if ft245.tx_fifo[i] != test_fifo_RX[i]:
            print "ft245.tx_fifo[{}]={}\ttest_fifo_RX[{}]={}".format(i,ft245.tx_fifo[i],i,test_fifo_RX[i])
            # print '%d %d' % (1, 2)
            # print '{} {}'.format(1, 2)
            raise TestFailure("RX data != TX data")

    print "-----------> EEEE-XITO (TX) <------------"
