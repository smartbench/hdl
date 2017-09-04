TOP = tx_rx
#SRC = $(wildcard ../modules/**/*.v) ../top/$(TOP).v
SRC = $(wildcard ../../*.v ../*.v)
INC = ../../../../inc/

# PNR OPT
PACKAGE = ct256
DEVICE = 8k
PCF = top_level.pcf

all: syn pnr pack

syn: $(TOP).blif
pnr : $(TOP).asc
pack: $(TOP).bin

$(TOP).blif: $(SRC)
	yosys -p "read_verilog -I$(INC) $(SRC); synth_ice40 -top $(TOP) -blif $(TOP).blif"

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
