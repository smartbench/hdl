import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Edge
from cocotb.result import TestFailure, TestError

@cocotb.coroutine
def nsTimer (t):
    yield Timer(t,units='ns')

class I2C_Master_Driver:
    def __init__ ( self, dut ):
        self.fifo_in = dut.fifo_in
        self.n_bytes = dut.n_bytes
        self.rdy = dut.rdy
        # self.start = dut.start
        self.ended = dut.ended
        self.clk = dut.clk

        self.rdy <= 0
        self.fifo_in <= 0

    @cocotb.coroutine
    def start_frame (self):
        self.start <= 1
        yield RisingEdge(self.clk)
        self.start <= 0
        yield RisingEdge(self.clk)

    @cocotb.coroutine
    def wait_ended (self):
        while self.ended.value.integer != 1:
            yield RisingEdge(self.clk)

    @cocotb.coroutine
    def wait_time (self):
        for i in range(10000):
            yield RisingEdge(self.clk)

    @cocotb.coroutine
    def fill_fifo (self,data):
        self.rdy <= 1
        for i in range(len(data)):
            self.fifo_in <= 0xFF & data[i]
            self.n_bytes <= 0xFF & (data[i] >> 8)
            yield RisingEdge(self.clk)
        self.rdy <= 0
        yield RisingEdge(self.clk)


    @cocotb.coroutine
    def driver ( self ):
        yield self.fill_fifo((1 | 0x0300,2,3,4))
        yield self.fill_fifo((0xAA | 0x0200,0x55,0xFF, 0x11))
        # yield self.start_frame()
        yield self.wait_ended()
        # yield self.wait_time()

        # yield self.start_frame()
        #yield self.wait_ended()
        yield self.wait_time()


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
        self.dut.sda_in <= 0
        yield self.scl_wait_high()
        yield self.scl_wait_low()
        self.dut.sda_in <= 1

    @cocotb.coroutine
    def wait_stop(self):
        yield self.scl_wait_high()
        yield self.sda_wait_high()



    @cocotb.coroutine
    def monitor ( self ):
        while True:
            print("waiting SDA low")
            yield self.sda_wait_low() # wait sda is in low state (start)
            self.dut._log.info("Starting frame")
            print("waiting SCL low")
            yield self.scl_wait_low()
            print("Receiving byte")
            yield self.receive_byte()
            print("Sending ack")
            yield self.send_ack()
            print("Receiving byte")
            yield self.receive_byte()
            print("Sending ack")
            yield self.send_ack()
            print("Receiving byte")
            yield self.receive_byte()
            print("Sending ack")
            yield self.send_ack()
            print("Receiving byte")
            yield self.receive_byte()
            print("Sending ack")
            yield self.send_ack()
            print("Waiting Stop")
            yield self.wait_stop()

            print("waiting SDA low")
            yield self.sda_wait_low() # wait sda is in low state (start)
            self.dut._log.info("Starting frame")
            print("waiting SCL low")
            yield self.scl_wait_low()
            print("Receiving byte")
            yield self.receive_byte()
            print("Sending ack")
            yield self.send_ack()
            print("Receiving byte")
            yield self.receive_byte()
            print("Sending ack")
            yield self.send_ack()
            print("Receiving byte")
            yield self.receive_byte()
            print("Sending ack")
            yield self.send_ack()
            print("Waiting Stop")
            yield self.wait_stop()

            print("waiting SDA low")
            yield self.sda_wait_low() # wait sda is in low state (start)
            self.dut._log.info("Starting frame")
            print("waiting SCL low")
            yield self.scl_wait_low()
            print("Receiving byte")
            yield self.receive_byte()
            print("Sending ack")
            yield self.send_ack()
            print("Waiting Stop")
            yield self.wait_stop()

            # print("Waiting SCL high")
            # yield [self.sda_wait_high(), self.scl_wait_high()]
            #if self.sda_out.value.integer == 1:
            # if self.scl.value.integer == 1:

            #
            # yield self.receive_byte()
            # yield self.send_ack()
            # yield self.receive_byte()
            # yield self.send_ack()
            # yield self.wait_stop()
            # self.dut._log.info("End frame")

@cocotb.coroutine
def Reset ( dut ):
    dut.rst <= 0
    for i in range(10): yield RisingEdge(dut.clk)
    dut.rst <= 1
    yield RisingEdge(dut.clk)
    dut.rst <= 0
    yield RisingEdge(dut.clk)

@cocotb.test()
def i2c_master_write_only( dut ):

    master_driver = I2C_Master_Driver( dut )
    slave = I2C_Slave( dut )

    cocotb.fork( Clock(dut.clk,10,units='ns').start() )
    yield Reset(dut)

    # cocotb.fork( Clock(dut.clk,10,units='ns').start() )


    cocotb.fork( master_driver.driver() )
    cocotb.fork( slave.monitor() )

    for i in range(70000): yield RisingEdge(dut.clk)

    print ("I2C read bytes")
    print ("Output: {}".format(slave.fifo))
