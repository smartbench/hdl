VERILOG_SOURCES = $(PWD)/../i2c_wrapper.v $(PWD)/../../i2c_master_write_only/i2c_master_write_only.v \
$(PWD)/../../test_modules/SB_IO.v $(PWD)/../../fully_associative_register/fully_associative_register.v \


TOPLEVEL=i2c_wrapper
MODULE= i2c_wrapper
EXTRA_ARGS= -I../../../inc/
include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim
