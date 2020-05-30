# In memory project flow
create_project -in_memory -part xc7a50tfgg484-1

# Where to put output from the build process
set buildDir build

# RTL Files
read_verilog rtl/axi_stream/axis_fifo_adapter.v
read_verilog rtl/axi_stream/axis_fifo.v
read_verilog -sv rtl/axi_stream/axis_ft245.sv
read_verilog -sv rtl/axon.sv
read_verilog -sv rtl/dendrite_mux.sv
read_verilog -sv rtl/dendrite.sv
read_verilog -sv rtl/dp_ram.sv
read_verilog -sv rtl/find_set_bit.sv
read_verilog -sv rtl/fire_dispatch.sv
read_verilog -sv rtl/mimas_top.sv
read_verilog -sv rtl/neuron.sv
read_verilog -sv rtl/neuron.sv.bk
read_verilog -sv rtl/packet_interface.sv
read_verilog -sv rtl/synapse.sv
read_verilog -sv rtl/ucaspian_core.sv
read_verilog -sv rtl/ucaspian.sv
read_verilog -sv rtl/util.sv

# Constraints
read_xdc pins/mimas_a7_rev2.xdc

# Synthesis
synth_design -top top

# Optimize, Place, and Route
opt_design
place_design
route_design

# Write reports
report_clock_utilization -file $buildDir/clocks.rpt
report_utilization -file $buildDir/utilization.rpt
report_timing_summary -file $buildDir/timing.rpt
report_power -file $buildDir/power.rpt

# Output Final bitfile
write_bitstream -force $buildDir/mimas_ucaspian.bit
