# In memory project flow
create_project -in_memory -part xc7a50tfgg484-1

# Where to put output from the build process
set script_dir [file dirname [file normalize [info script]]]
set rtl_dir "$script_dir/../rtl"
set syn_dir "$script_dir/../syn"
set ip_dir "$script_dir/../ip"
set build_dir "$script_dir/../build"

# RTL Files
read_verilog "$ip_dir/axi_stream/axis_fifo_adapter.v"
read_verilog "$ip_dir/axi_stream/axis_fifo.v"
read_verilog -sv "$ip_dir/axi_stream/axis_ft245.sv"
read_verilog -sv "$rtl_dir/axon.sv"
read_verilog -sv "$rtl_dir/dendrite_mux.sv"
read_verilog -sv "$rtl_dir/dendrite.sv"
read_verilog -sv "$rtl_dir/dp_ram.sv"
read_verilog -sv "$rtl_dir/find_set_bit.sv"
read_verilog -sv "$rtl_dir/fire_dispatch.sv"
read_verilog -sv "$rtl_dir/neuron.sv"
read_verilog -sv "$rtl_dir/packet_interface.sv"
read_verilog -sv "$rtl_dir/synapse.sv"
read_verilog -sv "$rtl_dir/ucaspian_core.sv"
read_verilog -sv "$rtl_dir/ucaspian.sv"
read_verilog -sv "$syn_dir/rtl/mimas_top.sv"

# Constraints
read_xdc "$syn_dir/pnr/mimas_a7_rev2.xdc"

# Synthesis
synth_design -top top

# Optimize, Place, and Route
opt_design
place_design
route_design

# Write reports
report_clock_utilization -file "$build_dir/clocks.rpt"
report_utilization -file "$build_dir/utilization.rpt"
report_timing_summary -file "$build_dir/timing.rpt"
report_power -file "$build_dir/power.rpt"

# Output Final bitfile
write_bitstream -force "$build_dir/mimas_ucaspian.bit"
