
TOP := top_level
SRC := $(filter-out $(wildcard ../modules/test_modules/*.v), $(wildcard ../modules/**/*.v ../top/$(TOP).v) )
INC := ../inc/
DEFINES := $(addprefix -D, $(DEF))

# PNR OPT
PACKAGE = ct256
DEVICE = 8k
PCF = top_level.pcf

all: syn pnr pack
.phony: show, prog, load-cram, clean

syn: $(TOP).blif
pnr : $(TOP).asc
pack: $(TOP).bin

show:
	echo $(SRC)

show-defines:
	echo $(DEFINES)

$(TOP).blif: $(SRC)
	yosys -p "read_verilog -I$(INC) $(DEFINES) $(SRC); synth_ice40 -top $(TOP) -blif $(TOP).blif"

$(TOP).asc: $(TOP).blif $(PCF)
	arachne-pnr -d $(DEVICE) -P $(PACKAGE) -p $(PCF) $(TOP).blif -o $(TOP).asc

$(TOP).bin: $(TOP).asc
	icepack $(TOP).asc $(TOP).bin

prog: $(TOP).bin
	iceprog $(TOP).bin

load-cram: $(TOP).bin
	iceprog -S $(TOP).bin

clean:
	rm $(TOP).bin $(TOP).asc $(TOP).blif --force
	rm *.bin *.asc *.blif *~ --force
