
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

BAUDRATE = 921600.0
F_CLK = 100e6
T_CLK_NS = 1.0e9/F_CLK
DIV = int(F_CLK/BAUDRATE)
PERIOD_NS = (1.0e9/BAUDRATE)

class UART:
    def __init__ (self,dut):
        #self.dut = dut
        self.clk = dut.clk_i
        self.rx = dut.rx
        self.tx = dut.tx

        self.rx <= 1
        self.tx_fifo = []
        self.rx_fifo = []

    def write (self,val):
        self.rx_fifo.append(val)

    @cocotb.coroutine
    def tx_monitor (self):
        while True:
            yield FallingEdge(self.tx)
            #yield nsTimer(PERIOD_NS/2.0)
            for i in range(DIV/2): yield RisingEdge(self.clk)
            yield FallingEdge(self.clk)
            data = 0
            if(self.tx.value.integer == 0):
                for idx in range(8):
                    #yield nsTimer(PERIOD_NS)
                    for i in range(DIV): yield RisingEdge(self.clk)
                    yield FallingEdge(self.clk)
                    aux  = self.tx.value.integer
                    data = data | (aux << idx)
                #yield nsTimer(PERIOD_NS)
                for i in range(DIV): yield RisingEdge(self.clk)
                yield FallingEdge(self.clk)
                print ("FDTI TX: {}".format(data))
                if(self.tx.value.integer == 1):
                    #print("OK")
                    self.tx_fifo.append(data)
                else:
                    print("ERROR")

    @cocotb.coroutine
    def rx_driver (self):
        print("DIV={}".format(DIV))
        while True:
            if(len(self.rx_fifo) > 0):
                data = (self.rx_fifo.pop(0) % 256)
                print("Rx Data = {}".format(data))
                self.rx <= 0
                #yield nsTimer(PERIOD_NS)
                for i in range(DIV): yield RisingEdge(self.clk)
                for i in range(8):
                    self.rx <= ((data >> i) % 256) & 0x01
                    #yield nsTimer(PERIOD_NS)
                    for i in range(DIV): yield RisingEdge(self.clk)
                self.rx <= 1
                for i in range(2*DIV): yield RisingEdge(self.clk)
            #yield Timer(PERIOD_NS/1e6, units='ms')
            #yield Timer(PERIOD_NS/1e6, units='ms')
            #yield nsTimer(PERIOD_NS)
            #yield nsTimer(PERIOD_NS)
            for i in range(4*DIV): yield RisingEdge(self.clk)
            #for i in range(DIV): yield RisingEdge(self.clk)


@cocotb.coroutine
def Reset (dut):
    dut.rst <= 0
    for i in range(10): yield RisingEdge(dut.clk_100M)
    dut.rst <= 1
    yield RisingEdge(dut.clk_100M)
    dut.rst <= 0
    yield RisingEdge(dut.clk_100M)


@cocotb.test()
def test (dut):
    test_fifo_RX = []
    test_fifo_TX = []
    uart = UART(dut)
    cocotb.fork(Clock(dut.clk_i,T_CLK_NS,units='ns').start())
    yield Reset(dut)
    #for i in range(100): si_tx.write(i+1)
    cocotb.fork(uart.rx_driver() )
    cocotb.fork(uart.tx_monitor() )
    for i in range(10): yield RisingEdge(dut.clk_100M)
    for i in range(128):
        uart.write((i+1)%256)
        test_fifo_RX.append((i+1)%256)
    # for i in range(10*600): yield RisingEdge(dut.clk_100M)
    # for i in range(150):
    #     uart.write((i+1)%256)
    #     test_fifo_RX.append((i+1)%256)
    for i in range(10*600): yield RisingEdge(dut.clk_100M)

    #if (uart.tx_fifo != [i for i in range(150)]):
    #    raise TestFailure("Simple Interface data != FT245 data (TX)")

    #for i in range(10*2000): yield RisingEdge(dut.clk_100M)
    while(len(uart.rx_fifo) > 0): yield RisingEdge(dut.clk_100M)
    #for i in range(10*20000): yield RisingEdge(dut.clk_100M)
    while(len(uart.tx_fifo) < 128): yield RisingEdge(dut.clk_100M)

    print("Length: Test_RX={}\tRX_remaining={}\tTX_fifo={}".format(len(test_fifo_RX), len(uart.rx_fifo), len(uart.tx_fifo)))
    if (len(test_fifo_RX) != len(uart.tx_fifo)):
        print("-----------------------")
        print("RX = ",test_fifo_RX)
        print("-----------------------")
        print("TX = ",uart.tx_fifo)
        raise TestFailure("RX != TX")

    for i in range(len(test_fifo_RX)):
        if(test_fifo_RX[i] != uart.tx_fifo[i]):
            print("-----------------------")
            print("RX = ",test_fifo_RX)
            print("-----------------------")
            print("TX = ",uart.tx_fifo)
            raise TestFailure("RX != TX")

    print "-----------> EEEE-XITO (RX) <------------"
