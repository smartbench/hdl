
# INTERFACE ?= uart
# BOARD ?= mainboard

ifeq ($(BOARD),breakout)
ifeq ($(INTERFACE),ft245)
	INTERFACE ?= ft245
else
	INTERFACE ?= uart
endif
	PACKAGE = ct256
	DEVICE = 8k
	FOLDER_TOP = ../top/$(BOARD)_$(INTERFACE)
	#TOP = top_level_$(BOARD)_$(INTERFACE)
else
	BOARD ?= mainboard
	PACKAGE = tq144:4k
	DEVICE = 8k
	FOLDER_TOP = ../top/$(BOARD)
	#TOP = top_level_$(BOARD)
endif

TOP := top_level
SRC := $(filter-out $(wildcard ../modules/test_modules/*.v), $(wildcard ../modules/**/*.v $(FOLDER_TOP)/$(TOP).v) )
INC := ../inc/
DEFINES := $(addprefix -D, $(DEF))
PCF = $(FOLDER_TOP)/$(TOP).pcf
BLIF = $(FOLDER_TOP)/$(TOP).blif
ASC = $(FOLDER_TOP)/$(TOP).asc
BIN = $(FOLDER_TOP)/$(TOP).bin

all: syn pnr pack
.phony: prog, load-cram, clean, show, show-defines, show-blocks

syn: $(BLIF)
pnr : $(ASC)
pack: $(BIN)

$(BLIF): $(SRC)
	yosys -p "read_verilog -I$(INC) $(DEFINES) $(SRC); synth_ice40 -top $(TOP) -blif $(BLIF)"
	@echo ""
	@echo "Synthesis - $(BLIF)"
	@echo ""


$(ASC): $(BLIF) $(PCF)
	arachne-pnr -r -d $(DEVICE) -P $(PACKAGE) -p $(PCF) $(BLIF) -o $(ASC)
	@echo ""
	@echo "Place and Route - $(ASC)"
	@echo ""

$(BIN): $(ASC)
	icepack $(ASC) $(BIN)
	@echo ""
	@echo "Pack - $(BIN)"
	@echo ""

prog: $(BIN)
	@echo "Writing $(BIN) into the flash memory (interface=$(INTERFACE))"
	iceprog $(BIN)
	@echo ""
	@echo " Program Flash - Interface = $(INTERFACE)"
	@echo ""

load-cram: $(BIN)
	@echo "Loading $(BIN) into the CRAM (interface=$(INTERFACE))"
	iceprog -S $(BIN)
	@echo ""
	@echo " Load CRAM - Interface = $(INTERFACE)"
	@echo ""

clean:
	@#rm $(TOP).bin $(ASC) $(BLIF) --force
	@rm ../top/*/*.bin ../top/*/*.asc ../top/*/*.blif *~ ../top/*/*.bin --force

show:
	@echo $(SRC)

show-defines:
	@echo $(DEFINES)

show-blocks: $(SRC)
	# http://www.clifford.at/yosys/cmd_show.html
	#yosys -p "read_verilog -I$(INC) $(DEFINES) ../top/$(TOP).v; show"
	yosys -p "read_verilog -I$(INC) $(DEFINES) $(FOLDER_TOP)/$(TOP).v; show -format svg -prefix ./show"
