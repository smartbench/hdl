
INT ?= uart
BOARD ?= mainboard

ifeq ($(BOARD),breakout)
	PACKAGE = ct256
	DEVICE = 8k
	FOLDER_TOP = ../top/$(BOARD)_$(INT)
	#TOP = top_level_$(BOARD)_$(INT)
else
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
.phony: show, prog, load-cram, clean

syn: $(BLIF)
pnr : $(ASC)
pack: $(BIN)

show:
	@echo $(SRC)

show-defines:
	@echo $(DEFINES)

show-blocks: $(SRC)
	# http://www.clifford.at/yosys/cmd_show.html
	#yosys -p "read_verilog -I$(INC) $(DEFINES) ../top/$(TOP).v; show"
	yosys -p "read_verilog -I$(INC) $(DEFINES) $(FOLDER_TOP)/$(TOP).v; show -format svg -prefix ./show"

$(BLIF): $(SRC)
	@echo pirulo $(PACKAGE)
	yosys -p "read_verilog -I$(INC) $(DEFINES) $(SRC); synth_ice40 -top $(TOP) -blif $(BLIF)"

$(ASC): $(BLIF) $(PCF)
	arachne-pnr -r -d $(DEVICE) -P $(PACKAGE) -p $(PCF) $(BLIF) -o $(ASC)

$(BIN): $(ASC)
	icepack $(ASC) $(BIN)

prog: $(BIN)
	@echo "Writing $(BIN) into the flash memory (interface=$(INT))"
	iceprog $(BIN)
	@echo ">>> Interface = $(INT) <<<"

load-cram: $(BIN)
	@echo "Loading $(BIN) into the CRAM (interface=$(INT))"
	iceprog -S $(BIN)
	@echo ">>> Interface = $(INT) <<<"

clean:
	@#rm $(TOP).bin $(ASC) $(BLIF) --force
	@rm ../top/*/*.bin ../top/*/*.asc ../top/*/*.blif *~ ../top/*/*.bin --force
