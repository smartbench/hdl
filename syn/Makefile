
TOP := top_level
SRC := $(filter-out $(wildcard ../modules/test_modules/*.v), $(wildcard ../modules/**/*.v ../top/$(TOP).v) )
INC := ../inc/
DEFINES := $(addprefix -D, $(DEF))


# PNR OPT
PACKAGE = tq144:4k
DEVICE = 8k
PCF = $(TOP).pcf

all: syn pnr pack
.phony: show, prog, load-cram, clean

syn: $(TOP).blif
pnr : $(TOP).asc
pack: $(TOP).bin

show:
	echo $(SRC)

show-defines:
	echo $(DEFINES)

show-blocks: $(SRC)
	# http://www.clifford.at/yosys/cmd_show.html
	#yosys -p "read_verilog -I$(INC) $(DEFINES) ../top/$(TOP).v; show"
	yosys -p "read_verilog -I$(INC) $(DEFINES) ../top/$(TOP).v; show -format svg -prefix ./show"

$(TOP).blif: $(SRC)
	yosys -p "read_verilog -I$(INC) $(DEFINES) $(SRC); synth_ice40 -top $(TOP) -blif $(TOP).blif"
	#-DUSING_UART=1

$(TOP).asc: $(TOP).blif $(PCF)
	arachne-pnr -d $(DEVICE) -P $(PACKAGE) -p $(PCF) $(TOP).blif -o $(TOP).asc

$(TOP).bin: $(TOP).asc
	icepack $(TOP).asc $(TOP).bin

prog: $(TOP).bin
	@echo "Writing $(TOP).bin into the flash memory (interface=$(INT))"
	iceprog $(TOP).bin
	@echo ">>> Interface = $(INT) <<<"

load-cram: $(TOP).bin
	@echo "Loading $(TOP).bin into the CRAM (interface=$(INT))"
	iceprog -S $(TOP).bin
	@echo ">>> Interface = $(INT) <<<"

clean:
	rm $(TOP).bin $(TOP).asc $(TOP).blif --force
	rm *.bin *.asc *.blif *~ --force
