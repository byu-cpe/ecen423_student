# final_iosystem.mk
#
# Makefile fragment for simulating and building the final iosystem module.
# Include this in your main makefile (include final_iosystem.mk).
#

# Include the common iosystem rules
# (these rules are separated into a different file so they can be used in future labs)
include ../resources/iosystem/iosystem.mk

INCLUDE_DIR = ../include

####################################################
# Simulation Rules
####################################################

# Makefile variable that lists all forwarding iosystem source files
FINAL_SOURCES = ../lab02/alu.sv ../lab03/regfile.sv \
	../lab11/riscv_final.sv \
	riscv_io_final.sv

# Rule for analyzing all of the files needed for the forwarding iosystem and testbench
analyze_final_iosystem: analyze_iosystem $(FINAL_SOURCES)
	xvlog -sv $(FINAL_SOURCES) -nolog --include $(INCLUDE_DIR)

# Elaboration rule for the forwarding iosystem without a testbench.
# Note that the debouncer is disabled for this simulation.
elab_final_iosystem: analyze_final_iosystem final_iosystem_text.mem final_iosystem_data.mem
	xelab riscv_io_final -s riscv_io_final --nolog  \
		-debug typical -timescale 1ns/100ps \
		-generic "TEXT_MEM=final_iosystem_text.mem" \
		-generic "DATA_MEM=final_iosystem_data.mem" \
		-generic "USE_DEBOUNCER=0" \
		-L unisims_ver glbl \

# Simulation of top-level design without testbench using the template tcl file
sim_final_iosystem_tcl: elab_final_iosystem
	xsim riscv_io_final --log sim_final_iosystem_tcl.log -tclbatch final_sim.tcl

# Simulation rule that starts the GUI
sim_final_iosystem_tcl_gui: elab_final_iosystem
	xsim riscv_io_final --nolog -gui

####################################################
# Implementation Rules
####################################################

# Build the base riscv_io_final.bit file (the .dcp file is created at the same time)
riscv_io_final.bit: riscv_io_final.sv final_iosystem_text.mem final_iosystem_data.mem
	vivado -mode batch -source implement_riscv_io_final.tcl -log riscv_io_final.log

# Rule that will generate the .dcp file if the .bit file is out of date.
riscv_io_final.dcp: riscv_io_final.bit

# Genrates a bitfile with a new font memory image. The .dcp file is also updated with the new memory image.
font.bit: riscv_io_final.dcp
	vivado -mode batch -source ../resources/load_mem.tcl \
		-tclargs updateFont riscv_io_final.dcp game_font_mem.txt font.bit font.dcp

font.dcp: font.bit

background_game_template.mem: background_game_template.txt
	python3 ../resources/generate_background.py $< $@

background.bit: font.dcp background_game_template.mem
	vivado -mode batch -source ../resources/load_mem.tcl \
		-tclargs updateBackground font.dcp background_game_template.mem background.bit background.dcp

####################################################
# Clean Rules
####################################################

clean_iosystem:
	rm -f final_iosystem*.mem final_iosystem_text.txt
	rm -f sim_final_iosystem*.log
	rm -f riscv_io_final*.log
	rm -f riscv_io_final*.rpt
	rm -f riscv_io_final.bit riscv_io_final.dcp font.bit font.dcp background.bit background.dcp
