# multicycle_iosystem.mk
#
# Makefile fragment for simulating and building the iosystem module.
# Include this in your main makefile by adding the following line near
# the top of your makefile
#
# include multicycle_iosystem.mk
#

# Include the common iosystem rules
# (these rules are separated into a different file so they can be used in future labs)
include ../resources/iosystem/iosystem.mk

INCLUDE_DIR = ../include

####################################################
# Simulation Rules
####################################################

# Makefile variable that lists all multicycle iosystem source files
MULTICYCLE_SOURCES = ../lab02/alu.sv ../lab03/regfile.sv \
	../lab05/riscv_simple_datapath.sv ../lab06/riscv_multicycle.sv \
	multicycle_iosystem.sv tb_multicycle_io.sv

# Rule for analyzing all of the files needed for the multicycle iosystem and testbench
analyze_multicycle_iosystem: analyze_iosystem $(MULTICYCLE_SOURCES)
	xvlog -sv $(MULTICYCLE_SOURCES) -nolog --include $(INCLUDE_DIR)

# Elaboration rule for the multicycle iosystem without a testbench.
# Note that the debouncer is disabled for this simulation.
elab_multicycle_iosystem: analyze_multicycle_iosystem multicycle_iosystem_text.mem
	xelab multicycle_iosystem -s multicycle_iosystem --nolog  \
		-debug typical -timescale 1ns/100ps \
		-generic "TEXT_MEM=multicycle_iosystem_text.mem" \
		-generic "USE_DEBOUNCER=0" \
		-L unisims_ver glbl \

# Simulation of top-level design without testbench using the template tcl file
sim_multicycle_iosystem_tcl_template: elab_multicycle_iosystem
	xsim multicycle_iosystem --nolog -tclbatch iosystem_template.tcl

# Simulation of top-level design without testbench using the template tcl file
sim_multicycle_iosystem_tcl: elab_multicycle_iosystem
	xsim multicycle_iosystem --log sim_multicycle_iosystem_tcl.log -tclbatch iosystem.tcl


sim_multicycle_iosystem_tcl_gui: elab_multicycle_iosystem
	xsim multicycle_iosystem --nolog -gui

# Elaboration and simulation rules
elab_tb_multicycle_io: analyze_multicycle_iosystem multicycle_iosystem_text.mem
	xelab --nolog tb_multicycle_io -s tb_multicycle_io \
		-debug typical -timescale 1ns/100ps \
		-generic "TEXT_MEM=multicycle_iosystem_text.mem" \
		-L unisims_ver glbl \

sim_multicycle_iosystem: elab_tb_multicycle_io
	xsim tb_multicycle_io --log sim_multicycle_iosystem.log --runall

####################################################
# Implementation Rules
####################################################

multicycle_iosystem.bit: multicycle_iosystem.sv multicycle_iosystem_text.mem
	vivado -mode batch -source implement_multicycle_iosystem.tcl -log multicycle_iosystem.log

####################################################
# Clean Rules
####################################################

clean_iosystem:
	rm -f multicycle_iosystem_text.mem multicycle_iosystem_text.txt multicycle_iosystem*.log
	rm -f sim_multicycle_iosystem*.log
	rm -f multicycle_iosystem.bit multicycle_iosystem*.rpt
