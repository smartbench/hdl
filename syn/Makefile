TOP = top
SRC = $(wildcard ../modules/**/*.v) ../top/$(TOP).v
INC = ../inc/

# PNR OPT
PACKAGE = ct256
DEVICE = 8k
PCF = top.pcf

all: syn pnr pack

syn: $(TOP).blif
pnr : $(TOP).asc
pack: $(TOP).bin

$(TOP).blif: $(SRC)
	yosys -p "read_verilog -I$(INC) $(SRC); synth_ice40 -blif $(TOP).blif"

$(TOP).asc: $(TOP).blif $(PCF)
	arachne-pnr -d $(DEVICE) -P $(PACKAGE) -p $(PCF) $(TOP).blif -o $(TOP).asc

$(TOP).bin: $(TOP).asc
	icepack $(TOP).asc $(TOP).bin

prog:
	iceprog $(TOP).bin

load-cram:
	iceprog -S $(TOP).bin

clean:
	rm $(TOP).bin $(TOP).asc $(TOP).blif --force
