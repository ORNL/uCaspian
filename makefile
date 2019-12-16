#############################################################################
# CASPIAN - A Programmable Neuromorphic Computing Architecture
# Parker Mitchell, 2019
#############################################################################

# Directories
RTL := rtl
SRC := src
INCLUDE := include
VERILATOR_OUT = vout
VERILATOR_MOD_OUT = vmod
BUILD := build

# Sources
RTL_SOURCES := $(wildcard $(RTL)/*.sv)
CPP_SOURCES := $(wildcard $(SRC)/*.cpp)

# Device Parameters
FAMILY-upduino ?= ice40
DEVICE-upduino ?= up5k
FOOTPRINT-upduino ?= sg48
PIN_SRC-upduino ?= upduino_v2.pcf
TOP-upduino ?= $(basename upduino_top.sv)
FREQ-upduino ?= 12

# Select the board
USB_DEV ?= 1-1:1.0
BOARD ?= upduino

# Select parameters based on the board
DEVICE := $(DEVICE-$(BOARD))
FOOTPRINT := $(FOOTPRINT-$(BOARD))
PIN_SRC := $(PIN_SRC-$(BOARD))
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
trace := false
ifeq ($(trace), true)
TRACEON = -DTRACEON
VERILATOR_FLAGS += --trace-fst
endif

.PHONY: all flash gui test lint clean

all: $(BUILD)/$(TOP).bin
flash: $(TOP).flash
gui: $(TOP).gui
test: $(VERILATOR_OUT)/Vucaspian
lib: $(VERILATOR_MOD_OUT)/Vucaspian__ALL.a

$(BUILD):
	mkdir -p $(BUILD)

# Synthesize the design for
$(BUILD)/%.json: $(RTL)/%.sv | $(BUILD)
	$(YOSYS) \
		-p 'read_verilog -sv $<' \
		-p 'synth_ice40 -top top -json $@' \
		-E .$(TOP).d

# Place & Route the synthesized netlist
$(BUILD)/%.asc: $(PIN_SRC) $(BUILD)/%.json | $(BUILD)
	$(PNR) \
		--$(DEVICE) \
		--placer heap \
		--package $(FOOTPRINT) \
		--asc $@ \
		--pcf $(PIN_SRC) \
		--freq $(FREQ) \
		--json $(basename $@).json

# Pack the ASCII respresentation into a proper binary representation
$(BUILD)/%.bin: $(BUILD)/%.asc | $(BUILD)
	$(ICEPACK) $< $@

# Program the board with the built design through the FTDI USB to SPI Bridge
%.flash: $(BUILD)/%.bin
	$(ICEPROG) -e 128 # Force a reset
	$(ICEPROG) $<
	# echo $(USB_DEV) | tee /sys/bus/usb/drivers/ftdi_sio/bind

# Open the Place & Route GUI to inspect the design
%.gui: $(BUILD)/%.json
	$(PNR) --gui --$(DEVICE) --pcf $(PIN_SRC) --freq $(FREQ) --json $<

# Convert Verilog to C++ with Verilator
$(VERILATOR_OUT)/Vucaspian: $(RTL_SOURCES) $(SRC)/ucaspian.cpp
	$(VERILATOR) \
	    $(VERILATOR_FLAGS) \
	    --Mdir $(VERILATOR_OUT) \
	    -I$(RTL) -I$(INCLUDE) \
	    -CFLAGS '-I../$(INCLUDE) $(TRACEON) $(CFLAGS)' \
	    --cc $(RTL)/$(VERILATOR_TOP).sv \
	    --exe $(CPP_SOURCES)
	$(MAKE) -C $(VERILATOR_OUT) -f V$(VERILATOR_TOP).mk V$(VERILATOR_TOP)

# Make just an archive -- will clean this up later
$(VERILATOR_MOD_OUT)/Vucaspian__all.a: $(RTL_SOURCES)
	$(VERILATOR) \
	    $(VERILATOR_FLAGS) \
	    --Mdir $(VERILATOR_MOD_OUT) \
	    -I$(RTL) -I$(INCLUDE) \
	    -CFLAGS '-I../$(INCLUDE) -DTRACEON $(CFLAGS)' \
	    --cc $(RTL)/$(VERILATOR_TOP).sv
	$(MAKE) -C $(VERILATOR_MOD_OUT) -f V$(VERILATOR_TOP).mk trace=true

# Have verilator lint the design
lint:
	$(VERILATOR) -Wall -I$(RTL) --lint-only $(RTL)/$(VERILATOR_TOP).sv

clean:
	$(RM) -rf $(BUILD) $(VERILATOR_OUT) $(VERILATOR_MOD_OUT)

-include .*.d
