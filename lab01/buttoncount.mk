# buttoncount.mk
#
# This is a makefile to demonstrate how to create simple rules for simulating,
# synthesizing, and building the ButtonCount application. This makefile provides
# an example of common makefile rules you will use all semester.
#

# This step will 'analyze' the three SV files.
# These steps will create a directory xsim.dir.  The 'clean' rule in this
# makefile will remove this directory. You will need to ignore
# this directory in your git repository. Adding the following line to your
# .gitignore file will do this:
# 
# xsim.dir/
#
# The 'clean' rule in this file will remove this directory.
analyze_buttoncount:
	xvlog ButtonCount.sv -sv --nolog
	xvlog ../include/synchronizer.sv -sv --nolog
	xvlog ../include/OneShot.sv -sv --nolog

# This rule will 'elaborate' the top-level design in preparation
# for simulation. The SV files need to be analyzed before the
# elaboration step.
elab_buttoncount: analyze_buttoncount
	xelab --nolog ButtonCount -s ButtonCount -debug typical

# This rule will simulate the ButtonCount design in GUI mode.
# Elaboration needs to be complete before simulation.
# It will create the waveform file ButtonCount.wdb
sim_buttoncount_gui: elab_buttoncount
	xsim ButtonCount -gui --nolog

# Rules for analyzing, analyzing and simulating the ButtonCount testbench.
analyze_buttoncount_tb: analyze_buttoncount
	xvlog ButtonCount_tb.sv -sv --nolog

elab_buttoncount_tb: analyze_buttoncount_tb
	xelab --nolog ButtonCount_tb -s ButtonCount_tb -debug typical

# Rule for simulating the testbench in command line mode. 
#  Note the use of the --runall option that will run the simulation until completion.
#  Note also the 'log' option that will create a log file for the simulation.
sim_buttoncount: elab_buttoncount_tb
	xsim ButtonCount_tb --log sim_buttoncount.log --runall

# This rule will perform the 'synthesis' step for the ButtonCount design.
# It relies on the 'synth_buttoncount.tcl' synthesis script.
# It will create the directory .Xil directory (which should be ignored
# and cleaned).
ButtonCount_synth.dcp: synth_buttoncount.tcl ButtonCount.sv
	vivado -mode batch -script synth_buttoncount.tcl -log synth_buttoncount.log

# This rule will perform the 'implementation' step for the ButtonCount design.
# The following files will be created with this command. Each of these commands
# should be ignored and cleaned.
# - ButtonCount.bit 
# - ButtonCount.dcp
# - implement_buttoncount.log
# - clockInfo.txt
# - timing.rpt
# - utilization.rpt
ButtonCount.bit: ButtonCount_synth.dcp
	vivado -mode batch -script implement_buttoncount.tcl -log implement_buttoncount.log

# All labs must have a 'clean' rule to remove generated files. This clean rule
# will remove all generated files for the ButtonCount design.
clean:
	rm -rf xsim.dir .Xil ButtonCount_tb.wdb xsim*.jou xelab.pb xvlog.log xvlog.pb
	rm -f ButtonCount.wdb sim_buttoncount.log
	rm -rf ButtonCount_synth.dcp synth_buttoncount*.log vivado*.jou vivado*.str
	rm -rf ButtonCount.bit clockInfo.txt timing.rpt utilization.rpt implement_buttoncount.log
	rm -rf ButtonCount.dcp implement_buttoncount*.log