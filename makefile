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
PINS-upduino ?= upduino_v2.pcf
TOP-upduino ?= $(basename upduino_top.sv)
FREQ-upduino ?= 24

FAMILY-upduino_uart ?= ice40
DEVICE-upduino_uart ?= up5k
FOOTPRINT-upduino_uart ?= sg48
PINS-upduino_uart ?= upduino_v2.pcf
TOP-upduino_uart ?= $(basename upduino_uart_top.sv)
FREQ-upduino_uart ?= 24

FAMILY-devr0 ?= ice40
DEVICE-devr0 ?= up5k
FOOTPRINT-devr0 ?= sg48
PINS-devr0 ?= dev_r0.pcf
TOP-devr0 ?= $(basename dev_r0_top.sv)
FREQ-devr0 ?= 25

# Select the board
# dev_r0
#USB_DEV ?= 1-1:1.0
#BOARD ?= devr0
# UPduino V2 or V3
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

# Select Icestorm programs
ICEPACK ?= icepack
ICEPROG ?= iceprog

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
	echo $(USB_DEV) | sudo tee /sys/bus/usb/drivers/ftdi_sio/bind

%.prog: $(BUILD)/%.bin
	$(ICEPROG) -I B -S $<

# Open the Place & Route GUI to inspect the design
%.gui: $(BUILD)/%.json
	$(PNR) --gui --$(DEVICE) --pcf $(PINS) --freq $(FREQ) --json $<

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

# Have verilator lint the design
lint:
	$(VERILATOR) -Wall -I$(RTL) --lint-only $(RTL)/$(VERILATOR_TOP).sv

clean:
	$(RM) -rf $(BUILD) $(VERILATOR_OUT)

-include .*.d
