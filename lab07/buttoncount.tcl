##########################################################################
#
# Filname: buttoncount.tcl
#
# This .tcl script will apply stimulus to the top-level pins of the FPGA
#
##########################################################################

# Procedure to press and release a button and propagate the change through the circuit
proc press_button {btn_name} {
    add_force $btn_name 1
    run 5 us
    add_force $btn_name 0
    run 2 us
}

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
run 3 us

# 2 btnu presses
press_button btnu
press_button btnu

# 3 btnd presses
press_button btnd
press_button btnd
press_button btnd

# 2 btnl presses
add_force sw 3 -radix hex
press_button btnl
add_force sw fffe -radix hex
press_button btnl

# 2 btnr presses
add_force sw 2 -radix hex
press_button btnr
add_force sw fffd -radix hex
press_button btnr

run 5 us

exit
