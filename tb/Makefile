RADIANT_VERSION ?= 3.2
MODELSIM_PATH ?= $(HOME)/.local/lscc/radiant/$(RADIANT_VERSION)/modeltech/linuxloem
MODELSIM_LICENSE ?= $(HOME)/.local/licenses/flexlm/lattice_radiant_license.dat

PATH := $(MODELSIM_PATH):$(PATH)
export LM_LICENSE_FILE = $(MODELSIM_LICENSE)

RTL = ../rtl
SRCS = \
	$(RTL)/dp_ram.sv \
	$(RTL)/find_set_bit.sv \
	$(RTL)/axon.sv \
	$(RTL)/dendrite.sv \
	$(RTL)/dendrite_mux.sv \
	$(RTL)/fire_dispatch.sv \
	$(RTL)/neuron.sv \
	$(RTL)/packet_interface.sv \
	$(RTL)/synapse.sv \
	$(RTL)/ucaspian_core.sv \
	$(RTL)/ucaspian.sv \
	ucaspian_tb.sv

VLIB = vlib
VCOM = vcom -2008 -quiet
VLOG = vlog -quiet -suppress 7033,7061
VSIM = vsim -batch -quiet

IVERILOG ?= iverilog
VVP ?= vvp

.SECONDARY: ucaspian_tb.wlf
.PHONY: all clean ucaspian_tb_modelsim

all: ucaspian_tb.vcd

test: ucaspian_tb_modelsim

work/_info:
	$(VLIB) work

work/_lib.qdb: $(SRCS) | work/_info
	$(VLOG) $^

%.wlf: work/_lib.qdb
	$(VSIM) -do "log -r /*;run -all;quit" -wlf $@ $* > $@.log

%.vcd: %.wlf
	wlf2vcd -o $@ $<

%.vvp: %.sv
	$(IVERILOG) -g2012 -I$(RTL) -Y.sv -y$(RTL) -o $@ $<

%.fst: %.vvp
	$(VVP) -N $< -fst 

%_icarus: %.vvp
	$(VVP) -N $<

%_modelsim: work/_lib.qdb
	$(VSIM) -do "run -all;quit" $* > $@.log

clean:
	-$(RM) -r work/ *.log *.wlf *.vvp *.fst *.vcd

