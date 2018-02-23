import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError


@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

class Reg_SI:
    def __init__( self, clk, addr, data, rdy, dut):
        self.dut = dut
        self._ADDR = 3
        self.clk = clk
        self.addr = addr
        self.data = data
        self.rdy = rdy
        self.addr_fifo = []
        self.data_fifo = []
        self.rdy <= 0

    @cocotb.coroutine
    def send_data(self, data):
        self.dut.register_addr <= self._ADDR
        self.dut.register_data <= data
        self.dut.register_rdy <= 1
        yield RisingEdge(self.clk)
        self.dut.register_rdy <= 0
        yield RisingEdge(self.clk)

    @cocotb.coroutine
    def send_dac(self, data):
        yield self.send_data(0xC0)  # Addr del dac
        yield self.send_data( data >> 8)  # Config
        yield self.send_data( (data & 0xFF) | 0x100 ) # los bits menos significativos

    @cocotb.coroutine
    def driver(self):
        test_data = ((2**i)-1 for i in range(11)) # envio 10 datos
        for i in test_data:
            self.dut._log.info("Hola {}".format(i))
            yield self.send_dac(i)
            yield Timer(400000, units='ns')

class I2C_Slave:
    def __init__(self, dut):
        self.dut = dut
        self.sda_out = dut.sda_out
        self.sda_in = dut.sda_in
        self.scl = dut.scl
        self.fifo = []
        self.clk = dut.clk
        self.byte = 0
        self.sda_in <= 1

    @cocotb.coroutine
    def scl_wait_low (self):
        while self.scl.value.integer != 0: # wait scl is in low state
            yield RisingEdge(self.clk)

    @cocotb.coroutine
    def scl_wait_high (self):
        while self.scl.value.integer != 1: # wait scl is in low state
            yield RisingEdge(self.clk)

    @cocotb.coroutine
    def sda_wait_low (self):
        while self.sda_out.value.integer != 0: # wait scl is in low state
            yield RisingEdge(self.clk)

    @cocotb.coroutine
    def sda_wait_high (self):
        while self.sda_out.value.integer != 1: # wait scl is in low state
            yield RisingEdge(self.clk)

    @cocotb.coroutine
    def receive_byte(self):
        val = 0
        for i in range(8):
            yield self.scl_wait_high()
            val = (val << 1) + self.sda_out.value.integer
            yield self.scl_wait_low()
        self.fifo.append(val)

    @cocotb.coroutine
    def send_ack(self):
        self.dut.sda_in = 0
        yield self.scl_wait_high()
        yield self.scl_wait_low()
        self.dut.sda_in = 1

    @cocotb.coroutine
    def wait_stop(self):
        yield self.scl_wait_high()
        yield self.sda_wait_high()


    @cocotb.coroutine
    def monitor ( self ):
        while True:
            yield self.sda_wait_low() # wait sda is in low state (start)
            self.dut._log.info("Starting frame")
            yield self.scl_wait_low()
            yield self.receive_byte()
            yield self.send_ack()
            yield self.receive_byte()
            yield self.send_ack()
            yield self.receive_byte()
            yield self.send_ack()
            yield self.wait_stop()
            self.dut._log.info("End frame")

@cocotb.coroutine
def Reset ( dut ):
    dut.rst <= 0
    for i in range(10): yield RisingEdge(dut.clk)
    dut.rst <= 1
    yield RisingEdge(dut.clk)
    dut.rst <= 0
    yield RisingEdge(dut.clk)

@cocotb.test()
def i2c_wrapper( dut ):

    slave = I2C_Slave( dut )
    reg = Reg_SI(dut.clk, dut.register_addr, dut.register_data, dut.register_rdy,dut)

    cocotb.fork( Clock(dut.clk,10,units='ns').start() )
    yield Reset(dut)

    cocotb.fork( reg.driver() )
    cocotb.fork( slave.monitor() )

    for i in range(430000): yield RisingEdge(dut.clk)

    print ("I2C read bytes")
    print ("Output: {}".format(slave.fifo))
