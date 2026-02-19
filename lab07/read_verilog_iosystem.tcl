# read_verilog_iosystem.tcl
#

# Read your verilog files from previous labs into the synthesis tool
read_verilog -sv ../lab02/alu.sv
read_verilog -sv ../lab03/regfile.sv
read_verilog -sv ../lab05/riscv_simple_datapath.sv
read_verilog -sv ../lab06/riscv_multicycle.sv

# Read the iosystem verilog files into the synthesis tool
read_verilog -sv multicycle_iosystem.sv

read_verilog -sv ../resources/iosystem/iosystem.sv
read_verilog -sv ../resources/iosystem/io_clocks.sv
read_verilog -sv ../resources/iosystem/riscv_mem.sv
read_verilog -sv ../resources/iosystem/cores/sevensegmentcontrol4.sv
read_verilog -sv ../resources/iosystem/cores/debounce.sv
read_verilog -sv ../resources/iosystem/cores/rx.sv
read_verilog -sv ../resources/iosystem/cores/tx.sv
read_verilog -sv ../resources/iosystem/cores/vga/vga_ctl3.sv
read_verilog -sv ../resources/iosystem/cores/vga/charGen3.sv
read_verilog -sv ../resources/iosystem/cores/vga/vga_timing.sv
read_verilog -sv ../resources/iosystem/cores/vga/font_rom.sv
read_verilog -sv ../resources/iosystem/cores/vga/charcolormem3bram.sv
read_verilog -sv ../resources/iosystem/cores/vga/brammacro.sv

# Read the constraints file
read_xdc ../resources/iosystem/iosystem.xdc

# Change the error message severity levels. Use this for all your
# synthesis and implementation Tcl scripts.
source ../resources/messages.tcl
