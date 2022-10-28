#############################################################################
# CASPIAN - A Programmable Neuromorphic Computing Architecture
# Parker Mitchell, 2019
#############################################################################

# Directories
RTL := rtl
SRC := sim/src
INCLUDE := sim/include
VERILATOR_OUT = vout
BUILD := build

# Core sources
UCASPIAN_RTL = $(wildcard $(RTL)/*.sv)

# IP sources
AXI_STREAM_RTL = $(wildcard ip/axi_stream/*.v  ip/axi_stream/*.sv)
AXIS_CLOCK_CONVERTER_RTL = $(wildcard ip/axis_clock_converter/*.sv)
ASYNC_FIFO_RTL = ip/dual_clock_async_fifo_design/dual_clock_async_fifo_design.sv
PULSE_STRETCHER_RTL = ip/osresearch/pulse_stretcher.v
PWM_RTL = ip/osresearch/pwm.v
DIVIDE_BY_N_RTL = ip/osresearch/divide_by_n.v
UART_RTL = ip/osresearch/uart.sv ip/osresearch/fifo.sv
SPI_RTL = ip/spi/spi_v4.sv ip/osresearch/fifo.sv
STREAM_FIFO_RTL = ip/stream/src/stream_fifo.sv
STREAM_UART_RTL = ip/uart/src/uart.sv ip/uart/src/uart_rx.sv ip/uart/src/uart_tx.sv $(STREAM_FIFO_RTL)

DEV_R0_TOP_RTL = $(AXI_STREAM_RTL)
UPDUINO_SPI_TOP_RTL = \
	$(SPI_RTL) \
	$(AXIS_CLOCK_CONVERTER_RTL) \
	$(ASYNC_FIFO_RTL) \
	$(PULSE_STRETCHER_RTL) \
	$(PWM_RTL) \
	$(DIVIDE_BY_N_RTL)
UPDUINO_TOP_RTL = \
	$(AXI_STREAM_RTL) \
	$(PULSE_STRETCHER_RTL) \
	$(PWM_RTL) \
	$(DIVIDE_BY_N_RTL)
UPDUINO_UART_TOP_RTL = \
	$(UART_RTL) \
	$(PULSE_STRETCHER_RTL) \
	$(PWM_RTL) \
	$(DIVIDE_BY_N_RTL)
UPDUINOLP_TOP_RTL = $(STREAM_UART_RTL)

CPP_SOURCES = $(wildcard $(SRC)/*.cpp)

# Select the board
USB_DEV ?= 1-1.4:1.0
BOARD ?= upduino

# Device parameters
ifeq ($(BOARD),upduino)
	TOP ?= upduino_top
	FAMILY = ice40
	DEVICE = up5k
	PACKAGE = sg48
	PCF = upduino_v2.pcf
	FREQ = 24
else ifeq ($(BOARD),dev_r0)
	TOP = dev_r0_top
	FAMILY = ice40
	DEVICE = up5k
	PACKAGE = sg48
	PCF = dev_r0.pcf
	FREQ = 25
else ifneq ($(BOARD),mimas)
	$(error Unsupported board)
endif

# Top module for uCaspian Core
VERILATOR_TOP = ucaspian
VERILATOR_CPP = V$(VERILATOR_TOP).cpp

# Select EDA programs
YOSYS ?= yosys
PNR ?= nextpnr-$(FAMILY)
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

TARGETS = $(filter-out mimas_top,$(basename $(notdir $(wildcard syn/rtl/*_top.sv))))

.PHONY: help flash prog gui test lint clean $(TARGETS)

help:
	@echo
	@echo ================================================================
	@echo " uCaspian"
	@echo
	@for target in $(TARGETS); do \
		echo " make $$target"; \
	done
	@echo ================================================================
	@echo

$(TARGETS): %: $(BUILD)/%.bin

all: $(TARGETS)

flash: $(TOP).flash

prog: $(TOP).prog

gui: $(TOP).gui

test: $(VERILATOR_OUT)/Vucaspian

$(BUILD):
	mkdir -p $(BUILD)

# Design specific sources and constraints
$(BUILD)/dev_r0_top.json: $(DEV_R0_TOP_RTL)
$(BUILD)/dev_r0_top.asc: PCF = dev_r0.pcf

$(BUILD)/upduinolp_top.json: $(UPDUINOLP_TOP_RTL)
$(BUILD)/upduinolp_top.asc: PCF = upduinolp.pcf

$(BUILD)/upduino_spi_top.json: $(UPDUINO_SPI_TOP_RTL)

$(BUILD)/upduino_top.json: $(UPDUINO_TOP_RTL)

$(BUILD)/upduino_uart_top.json: $(UPDUINO_UART_TOP_RTL)

# Synthesize the design
$(BUILD)/%.json: syn/rtl/%.sv $(UCASPIAN_RTL) | $(BUILD)
	$(YOSYS) \
		-p 'read_verilog -sv $^' \
		-p 'synth_ice40 -top top -json $@' \

# Place & Route the synthesized netlist
$(BUILD)/%.asc: $(BUILD)/%.json | syn/pnr/$(PCF) $(BUILD)
	$(PNR) \
		--$(DEVICE) \
		--placer heap \
		--package $(PACKAGE) \
		--asc $@ \
		--pcf syn/pnr/$(PCF) \
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
	$(PNR) --gui --$(DEVICE) --package $(PACKAGE) --pcf $(PINS) --freq $(FREQ) --json $<

# Convert Verilog to C++ with Verilator
$(VERILATOR_OUT)/Vucaspian: $(UCASPIAN_RTL) $(SRC)/ucaspian.cpp
	$(VERILATOR) \
	    $(VERILATOR_FLAGS) \
	    --Mdir $(VERILATOR_OUT) \
	    -I$(RTL) -I$(INCLUDE) \
		-CFLAGS '-I../$(INCLUDE) $(CFLAGS)' \
		--top $(VERILATOR_TOP) \
	    --cc $(UCASPIAN_RTL) \
	    --exe $(CPP_SOURCES)
	$(MAKE) -C $(VERILATOR_OUT) -f V$(VERILATOR_TOP).mk V$(VERILATOR_TOP)

$(BUILD)/mimas_ucaspian.bit:
	$(VIVADO) -mode batch -nolog -nojournal -source syn/mimas.tcl

mimas_bit: $(BUILD)/mimas_ucaspian.bit

mimas_prog: $(BUILD)/mimas_ucaspian.bit
	$(XC3SPROG) -c mimas_a7 $(BUILD)/mimas_ucaspian.bit

# Have verilator lint the design
lint:
	$(VERILATOR) -Wall -I$(RTL) --lint-only $(UCASPIAN_RTL)

clean:
	$(RM) -rf $(BUILD) $(VERILATOR_OUT)
