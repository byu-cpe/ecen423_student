# forwarding_iosystem.mk
#
# Makefile fragment for simulating and building the forwarding iosystem module.
# Include this in your main makefile by adding the following line near
# the top of your makefile
#
# include forwarding_iosystem.mk
#

# Include the common iosystem rules
# (these rules are separated into a different file so they can be used in future labs)
include ../resources/iosystem/iosystem.mk

INCLUDE_DIR = ../include

####################################################
# Simulation Rules
####################################################

# Makefile variable that lists all forwarding iosystem source files
FORWARDING_SOURCES = ../lab02/alu.sv ../lab03/regfile.sv \
	../lab05/riscv_simple_datapath.sv ../lab09/riscv_forwarding_pipeline.sv \
	forwarding_iosystem.sv

# Rule for analyzing all of the files needed for the forwarding iosystem and testbench
analyze_forwarding_iosystem: analyze_iosystem $(FORWARDING_SOURCES)
	xvlog -sv $(FORWARDING_SOURCES) -nolog --include $(INCLUDE_DIR)

# Elaboration rule for the forwarding iosystem without a testbench.
# Note that the debouncer is disabled for this simulation.
elab_forwarding_iosystem: analyze_forwarding_iosystem forwarding_iosystem_text.mem forwarding_iosystem_data.mem
	xelab forwarding_iosystem -s forwarding_iosystem --nolog  \
		-debug typical -timescale 1ns/100ps \
		-generic "TEXT_MEM=forwarding_iosystem_text.mem" \
		-generic "DATA_MEM=forwarding_iosystem_data.mem" \
		-generic "USE_DEBOUNCER=0" \
		-L unisims_ver glbl \

# Simulation of top-level design without testbench using the template tcl file
sim_forwarding_iosystem_tcl_template: elab_forwarding_iosystem
	xsim forwarding_iosystem --nolog -tclbatch vga_sim.tcl

# Simulation of top-level design without testbench using the template tcl file
sim_forwarding_iosystem_tcl: elab_forwarding_iosystem
	xsim forwarding_iosystem --log sim_forwarding_iosystem_tcl.log -tclbatch vga_sim_new.tcl

# Simulation rule that starts the GUI
sim_forwarding_iosystem_tcl_gui: elab_forwarding_iosystem
	xsim forwarding_iosystem --nolog -gui

####################################################
# Implementation Rules
####################################################

# Build the base forwarding_iosystem.bit file
forwarding_iosystem.bit: forwarding_iosystem.sv forwarding_iosystem_text.mem forwarding_iosystem_data.mem
	vivado -mode batch -source implement_forwarding_iosystem.tcl -log forwarding_iosystem.log

# Create a bitstream for the move_char test program by loading the appropriate memory files into the design checkpoint
forwarding_defuse.bit: forwarding_iosystem.bit defuse_text.mem defuse_data.mem
	vivado -mode batch -source ../resources/load_mem.tcl -log forwarding_defuse.log \
		-tclargs updateMem forwarding_iosystem.dcp \
		defuse_text.mem defuse_data.mem forwarding_defuse.bit 

####################################################
# Clean Rules
####################################################

clean_iosystem:
	rm -f forwarding_iosystem_*.mem forwarding_iosystem_text.txt forwarding_iosystem*.log
	rm -f defuse_*.mem defuse_text.txt
	rm -f sim_forwarding_iosystem*.log
	rm -f forwarding_iosystem.bit forwarding_iosystem.dcp forwarding_iosystem*.rpt
	rm -f forwarding_defuse.bit
