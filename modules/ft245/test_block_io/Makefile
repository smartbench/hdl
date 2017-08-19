#VERILOG_SOURCES = $(PWD)/../ft245.v $(PWD)/../test_block_io/SB_IO.v $(PWD)/../ft245_block.v
VERILOG_SOURCES = $(wildcard $(PWD)/../*.v) $(wildcard $(PWD)/*.v)
TOPLEVEL=ft245_block
MODULE= ft245_block
EXTRA_ARGS= -I../../../inc/
include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim
