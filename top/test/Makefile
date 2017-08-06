VERILOG_SOURCES =  $(wildcard $(PWD)/../../modules/**/*.v) $(wildcard $(PWD)/../*.v)
TOPLEVEL= top
MODULE= top
EXTRA_ARGS= "-I../../inc/"		# Add to includes path the parent dir
include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim
