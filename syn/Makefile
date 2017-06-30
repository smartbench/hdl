



TOP = breadboard_top
SRC = $(wildcard ../modules/*.v) ../top/$(TOP).v

# PNR OPT
PACKAGE = ct256
DEVICE = 8k
PCF = breadboard.pcf

all: syn pnr pack

syn: $(TOP).blif
pnr : $(TOP).asc
pack: $(TOP).bin

$(TOP).blif: $(SRC)
	yosys -p "synth_ice40 -blif $(TOP).blif" $(SRC)

$(TOP).asc: $(TOP).blif
	arachne-pnr -d $(DEVICE) -P $(PACKAGE) -p $(PCF) $(TOP).blif -o $(TOP).asc      

$(TOP).bin: $(TOP).asc
	icepack $(TOP).asc $(TOP).bin

prog:
	iceprog $(TOP).bin

clean:
	rm $(TOP).bin $(TOP).asc $(TOP).blif --force

