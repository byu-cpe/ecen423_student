# implement_multicycle_iosystem.tcl
#

# Read all of the verilog files and constraints
source read_verilog_iosystem.tcl

# Run the sythesis command
synth_design -top multicycle_iosystem -part xc7a35tcpg236-1 -verbose -include_dirs {../include} -generic {TEXT_MEM=multicycle_iosystem_text.mem}

# Perform design optimization, placement, and routing
opt_design
place_design
route_design

# Generate reports
report_timing_summary -max_paths 10 -report_unconstrained -file multicycle_iosystem_timing.rpt -warn_on_violation
report_utilization -file multicycle_iosystem_utilization.rpt

# Generate the bitstream and final design checkpoint
write_bitstream -force multicycle_iosystem.bit
# write_checkpoint -force multicycle_iosystem.dcp
