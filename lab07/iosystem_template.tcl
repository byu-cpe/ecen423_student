##########################################################################
#
# Filname: iosystem_template.tcl
#
# This .tcl script will apply stimulus to the top-level pins of the FPGA
#
##########################################################################


# Start the simulation over
restart

# Run circuit with no input stimulus settings
run 20 ns

# Set the clock to oscillate with a period of 10 ns
add_force clk {0} {1 5} -repeat_every 10
# Run the circuit for a bit
run 40 ns

# set the top-level inputs
add_force btnc 0
add_force btnl 0
add_force btnr 0
add_force btnu 0
add_force btnd 0
add_force sw 0
add_force RsTx 1
run 8 us

puts "Change switches and observe LEDs"
add_force sw a5a5 -radix hex
run 4 us

exit