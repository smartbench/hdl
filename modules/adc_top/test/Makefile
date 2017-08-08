# VERILOG_SOURCES =$(PWD)/../adc_top.v $(PWD)/../adc_interface.v $(PWD)/../moving_average.v
VERILOG_SOURCES =$(wildcard $(PWD)/../**/*.v) $(wildcard $(PWD)/../*.v)
TOPLEVEL= adc_top
MODULE= adc_top_test
include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim
