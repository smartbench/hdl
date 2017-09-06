
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
F_CLK = 100.0e6
PERIOD_NS = (1.0e9/BAUDRATE)
DIV = int(F_CLK/BAUDRATE)

class UART:
    def __init__ (self,dut):
        #self.dut = dut
        self.clk = dut.clk
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
            if(self.tx.value.integer == 1):
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
                    print("OK")
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
                print("Slave read = {}",format(self.data.value.integer))
            yield RisingEdge(self.clk)

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
    dut.tx_enable <= 1
    dut.rx_enable <= 1
    uart = UART(dut)
    slave = SI_Slave(dut.clk, dut.rst , dut.rx_data, dut.rx_rdy, dut.rx_ack)
    master = SI_Master(dut.clk, dut.rst , dut.tx_data, dut.tx_rdy, dut.tx_ack)
    cocotb.fork(Clock(dut.clk,10,units='ns').start())
    yield Reset(dut)

    cocotb.fork(slave.monitor())
    cocotb.fork(master.driver())
    cocotb.fork(uart.rx_driver() )
    cocotb.fork(uart.tx_monitor() )

    for i in range(1100): yield RisingEdge(dut.clk)
    for i in range(20):
        aux = (i+1)%256
        #aux = 0x55
        uart.write(aux)
        test_fifo_RX.append(aux)
    #for i in range(1000000): yield RisingEdge(dut.clk)
    # for i in range(150):
    #     aux = (i+1)%256
    #     uart.write(aux)
    #     test_fifo_RX.append(aux)
    # for i in range(10*600): yield RisingEdge(dut.clk)
    #
    # for i in range(10*130): yield RisingEdge(dut.clk)
    while(len(uart.rx_fifo) != 0):
        for i in range(100): yield RisingEdge(dut.clk)
        #print("Len(Rx fifo) = {}".format(len(uart.rx_fifo)))

    while(len(slave.fifo) < len(test_fifo_RX)):
        for i in range(100): yield RisingEdge(dut.clk)
        #print("Len(slave.fifo) = {} . Should reach #{}".format(len(slave.fifo), len(test_fifo_RX)) )
    print("Length RX = {}\tLength TX = {}".format(len(test_fifo_RX),len(slave.fifo)))
    #if ( test_fifo_RX != uart.tx_fifo ):
    for i in range(len(slave.fifo)):
        if(test_fifo_RX[i] != slave.fifo[i]):
            print("-----------------------")
            print("RX = ",test_fifo_RX)
            print("-----------------------")
            print("Slave = ",slave.fifo)
            raise TestFailure("RX != Slave")

    print "-----------> EEEE-XITO (RX) <------------"
