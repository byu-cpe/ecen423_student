# iosystem.mk
#
# Makefile fragment for simulating and building the iosystem module.
# Include this in your main makefile by adding the following line near
# the top of your makefile
#
# include iosystem.mk
#
# The rules in this file assume that you are running from a lab directory
# (i.e., labxx)

####################################################
# Rules for generating the .mem files for iosystems
####################################################

# Makefile variable for the RARS simulator/assembler
RARS = java -jar ../resources/rars1_6.jar

# Rules for creating the text .mem file and the assembly debug file
%_text.mem: %.s
	$(RARS) mc CompactTextAtZero $< a dump .text HexText $@ dump .text SegmentWindow $*_text.txt

# The data memory file is not needed but the rule is added as an example
%_data.mem: %.s
	$(RARS) mc CompactTextAtZero $<  a dump .data HexText $@

####################################################
# Simulation Rules
####################################################

# makefile constants for specifying the location of the iosystem source files
RESOURCES_LOC = ../resources
IOSYSTEM_LOC = $(RESOURCES_LOC)/iosystem
CORES_LOC = $(IOSYSTEM_LOC)/cores
VGA_LOC = $(CORES_LOC)/vga

# Makefile variable that lists all iosystem source files
IOSYSTEM_SV_SOURCES = \
	$(IOSYSTEM_LOC)/iosystem.sv $(IOSYSTEM_LOC)/io_clocks.sv $(IOSYSTEM_LOC)/riscv_mem.sv \
	$(CORES_LOC)/sevensegmentcontrol4.sv $(CORES_LOC)/debounce.sv \
	$(CORES_LOC)/rx.sv $(CORES_LOC)/tx.sv \
	$(VGA_LOC)/vga_ctl3.sv $(VGA_LOC)/charGen3.sv \
	$(VGA_LOC)/vga_timing.sv $(VGA_LOC)/font_rom.sv \
	$(VGA_LOC)/charcolormem3bram.sv $(VGA_LOC)/brammacro.sv
IOSYSTEM_V_SOURCES = $(RESOURCES_LOC)/glbl.v

# Rule for analyzing all of the iosystem source files
analyze_iosystem: $(IOSYSTEM_SV_SOURCES) $(IOSYSTEM_V_SOURCES)
	xvlog -sv $(IOSYSTEM_SV_SOURCES) -nolog --include $(INCLUDE_DIR)
	xvlog $(IOSYSTEM_V_SOURCES) -nolog --include $(INCLUDE_DIR)
