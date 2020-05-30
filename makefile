#############################################################################
# CASPIAN - A Programmable Neuromorphic Computing Architecture
# Parker Mitchell, 2019
#############################################################################

# Directories
RTL := rtl
SRC := src
INCLUDE := include
VERILATOR_OUT = vout
BUILD := build

# Sources
RTL_SOURCES := $(wildcard $(RTL)/*.sv)
CPP_SOURCES := $(wildcard $(SRC)/*.cpp)

# Device Parameters
FAMILY-upduino ?= ice40
DEVICE-upduino ?= up5k
FOOTPRINT-upduino ?= sg48
PINS-upduino ?= pins/upduino_v2.pcf
TOP-upduino ?= $(basename upduino_top.sv)
FREQ-upduino ?= 24

FAMILY-devr0 ?= ice40
DEVICE-devr0 ?= up5k
FOOTPRINT-devr0 ?= sg48
PINS-devr0 ?= pins/dev_r0.pcf
TOP-devr0 ?= $(basename dev_r0_top.sv)
FREQ-devr0 ?= 30

# Select the board
USB_DEV ?= 1-1:1.0
BOARD ?= devr0

# Select parameters based on the board
DEVICE := $(DEVICE-$(BOARD))
FOOTPRINT := $(FOOTPRINT-$(BOARD))
PINS := $(PINS-$(BOARD))
TOP := $(TOP-$(BOARD))
FREQ = $(FREQ-$(BOARD))

# Top module for uCaspian Core
VERILATOR_TOP = ucaspian
VERILATOR_CPP = V$(VERILATOR_TOP).cpp

# Select EDA programs
YOSYS ?= yosys
PNR ?= nextpnr-$(FAMILY-$(BOARD))
VERILATOR ?= verilator
VIVADO ?= vivado 

# Select Icestorm programs
ICEPACK ?= icepack
ICEPROG ?= iceprog

# For JTAG programming of Xilinx FPGAs
XC3SPROG ?= xc3sprog

# C++ (for Verilator)
CXX ?= g++
CFLAGS ?= -O2 -march=native -mtune=native -fPIC -std=c++14 -fvisibility=hidden -flto

# Verilator options
VERILATOR_FLAGS = -Wno-fatal -O3 

# Waveform traces
VERILATOR_FLAGS += --trace-fst

.PHONY: all flash gui test lint clean

all: $(BUILD)/$(TOP).bin
flash: $(TOP).flash
prog: $(TOP).prog
gui: $(TOP).gui
test: $(VERILATOR_OUT)/Vucaspian

$(BUILD):
	mkdir -p $(BUILD)

# Synthesize the design for
$(BUILD)/%.json: $(RTL)/%.sv | $(BUILD)
	$(YOSYS) \
		-p 'read_verilog -sv $<' \
		-p 'synth_ice40 -top top -json $@' \
		-E .$(TOP).d

# Place & Route the synthesized netlist
$(BUILD)/%.asc: $(PINS) $(BUILD)/%.json | $(BUILD)
	$(PNR) \
		--$(DEVICE) \
		--placer heap \
		--package $(FOOTPRINT) \
		--asc $@ \
		--pcf $(PINS) \
		--freq $(FREQ) \
		--json $(basename $@).json

# Pack the ASCII respresentation into a proper binary representation
$(BUILD)/%.bin: $(BUILD)/%.asc | $(BUILD)
	$(ICEPACK) $< $@

# Program the board with the built design through the FTDI USB to SPI Bridge
%.flash: $(BUILD)/%.bin
	$(ICEPROG) -e 128 # Force a reset
	$(ICEPROG) $<

%.prog: $(BUILD)/%.bin
	$(ICEPROG) -I B -S $<

# Open the Place & Route GUI to inspect the design
%.gui: $(BUILD)/%.json
	$(PNR) --gui --$(DEVICE) --package $(FOOTPRINT) --pcf $(PINS) --freq $(FREQ) --json $<

# Convert Verilog to C++ with Verilator
$(VERILATOR_OUT)/Vucaspian: $(RTL_SOURCES) $(SRC)/ucaspian.cpp
	$(VERILATOR) \
	    $(VERILATOR_FLAGS) \
	    --Mdir $(VERILATOR_OUT) \
	    -I$(RTL) -I$(INCLUDE) \
	    -CFLAGS '-I../$(INCLUDE) $(CFLAGS)' \
	    --cc $(RTL)/$(VERILATOR_TOP).sv \
	    --exe $(CPP_SOURCES)
	$(MAKE) -C $(VERILATOR_OUT) -f V$(VERILATOR_TOP).mk V$(VERILATOR_TOP)

$(BUILD)/mimas_ucaspian.bit:
	$(VIVADO) -mode batch -nolog -nojournal -source scripts/mimas.tcl

mimas_bit: $(BUILD)/mimas_ucaspian.bit

mimas_prog: $(BUILD)/mimas_ucaspian.bit
	$(XC3SPROG) -c mimas_a7 $(BUILD)/mimas_ucaspian.bit

# Have verilator lint the design
lint:
	$(VERILATOR) -Wall -I$(RTL) --lint-only $(RTL)/$(VERILATOR_TOP).sv

clean:
	$(RM) -rf $(BUILD) $(VERILATOR_OUT)

-include .*.d
