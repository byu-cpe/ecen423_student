# implement_forwarding_iosystem.tcl
#

# Read all of the verilog files and constraints
source ../resources/iosystem/read_iosystem.tcl

# Read local files
read_verilog -sv ../lab02/alu.sv
read_verilog -sv ../lab03/regfile.sv
read_verilog -sv ../lab09/riscv_forwarding_pipeline.sv
read_verilog -sv forwarding_iosystem.sv

# Run the sythesis command
synth_design -top forwarding_iosystem -part xc7a35tcpg236-1 -verbose -include_dirs {../include} \
    -generic {TEXT_MEM=forwarding_iosystem_text.mem} \
    -generic {DATA_MEM=forwarding_iosystem_data.mem} \

# Perform design optimization, placement, and routing
opt_design
place_design
route_design

# Generate reports
report_timing_summary -max_paths 10 -report_unconstrained -file forwarding_iosystem_timing.rpt -warn_on_violation
report_utilization -file forwarding_iosystem_utilization.rpt

# Generate the bitstream and final design checkpoint
write_bitstream -force forwarding_iosystem.bit
write_checkpoint -force forwarding_iosystem.dcp
