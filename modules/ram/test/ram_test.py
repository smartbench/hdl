''' toDo:
    * Read and write at the same time -> OK
    * Write the full length and read back
    * Instantiate a block ram with WR_DATA_WIDTH=8bits and RD_DATA_WIDTH=16/32bits
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


class MEM_WRITE:
    def __init__ (self, wr_clk, wr_data, wr_addr, wr_en ):
        self.wr_clk = wr_clk
        self.wr_data = wr_data
        self.wr_addr = wr_addr
        self.wr_en = wr_en
        self.wr_cont_addr = 0
        self.fifo = []

    def write(self,val):
        self.fifo.append(val)

    @cocotb.coroutine
    def wr_driver (self):
        while True:
            yield RisingEdge(self.wr_clk)
            if len(self.fifo) > 0 :
                self.wr_en <= 1
                self.wr_addr <= self.wr_cont_addr
                # check below line, maybe
                self.wr_cont_addr += 1
                #self.wr_cont_addr.value.integer <= self.wr_cont_addr.value.integer + 1
                self.wr_data <= self.fifo.pop(0)
            else:
                self.wr_en <= 0


class MEM_READ:
    def __init__ (self, rd_clk, rd_data, rd_addr): #without rd_enable
        self.rd_clk = rd_clk
        self.rd_data = rd_data
        self.rd_addr = rd_addr
        self.rd_cont_addr = 0
        self.reading = False
        self.fifo = []

    def start_reading (self):
        self.reading = True

    @cocotb.coroutine
    def rd_driver (self):
        while True:
            yield RisingEdge(self.rd_clk)
            if self.reading == True:
                self.rd_addr <= self.rd_cont_addr
                self.rd_cont_addr += 1



    @cocotb.coroutine
    def monitor (self):
        while True:
            yield RisingEdge(self.rd_clk)
            if self.reading == True:
                self.fifo.append(self.rd_data.value)
                # self.fifo.append(self.rd_data.value.integer) <- Not working

# RD and WR simultaneous
# Can perform simultaneous RD and WR (but not in the same address)
@cocotb.test()
def test (dut):
    # RD and WR operations connected to the same clock
    # fifo_test = []
    mem_write = MEM_WRITE(dut.wclk, dut.din, dut.waddr, dut.write_en )
    mem_read = MEM_READ(dut.wclk, dut.dout, dut.raddr)
    cocotb.fork(Clock(dut.wclk, 10, units='ns').start())
    cocotb.fork(Clock(dut.rclk, 10, units='ns').start())
    for i in range(10): mem_write.write(randint(0,15))
    # for i in range(10):
    #     aux = i
    #     fifo_test.append(aux)
    #     mem_write.write(aux)

    cocotb.fork(mem_write.wr_driver() )
    cocotb.fork(mem_read.rd_driver() )
    cocotb.fork(mem_read.monitor() )
    yield RisingEdge(dut.wclk)
    mem_read.start_reading()
    for i in range (12): yield RisingEdge(dut.wclk)
