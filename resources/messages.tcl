# This file contains several TCL commands for changing the default settings of your projects.
# These settings change the severity level of certain messages to make the messages
# more meaningful. Some settings will be upgraded and cause an error while others
# will be downgraded to avoid unncessary warnings.

####################
# Upgrade messages
####################
set_msg_config -new_severity "ERROR" -id "Synth 8-87"
#INFO: [Synth 8-155] case statement is not full and has no default
set_msg_config -new_severity "WARNING" -id "Synth 8-155"
# Infer Latch
set_msg_config -new_severity "ERROR" -id "Synth 8-327"
set_msg_config -new_severity "ERROR" -id "Synth 8-3352"
# Multi-driven net
set_msg_config -new_severity "ERROR" -id "Synth 8-5559"
# [Synth 8-5972] variable 'Zero' cannot be written by both continuous and procedural assignments
set_msg_config -new_severity "ERROR" -id "Synth 8-5972"
set_msg_config -new_severity "ERROR" -id "Synth 8-6090"
# "multi-driven net" caused by continuous assign statements along with wire declaration
set_msg_config -new_severity "ERROR" -id "Synth 8-6858"
# Upgrade the 'multi-driven net on pin' message to ERROR
set_msg_config -new_severity "ERROR" -id "Synth 8-6859"
# Upgrade the 'The design failed to meet the timing requirements' message to ERROR
set_msg_config -new_severity "ERROR" -id "Timing 38-282"
# Upgrade the 'actual bit length 8 differs from formal bit length 22 for port 'o_led' message
set_msg_config -new_severity "ERROR" -id "VRFC 10-3091"
####################
# Downgrade messages
####################
# Downgrade the 'There are no user specified timing constraints' to WARNING
set_msg_config -new_severity "WARNING" -id "Timing 38-313"
# Downgrade the 'no constraints slected for write' from a warning to INFO
set_msg_config -new_severity "INFO" -id "Constraints 18-5210"
# Downgrade the 'WARNING: [DRC RTSTAT-10] No routable loads: 35 net(s) have no routable loads.' to INFO
set_msg_config -new_severity "INFO" -id "DRC RTSTAT-10"
# Downgrade the waraning 'WARNING: [Synth 8-3331] design riscv_simple_datapath has unconnected port instruction[14]' to INFO
set_msg_config -new_severity "INFO" -id "Synth 8-3331"
# WARNING: [Synth 8-7080] Parallel synthesis criteria is not met
set_msg_config -new_severity "INFO" -id "Synth 8-7080"
# WARNING: [Synth 8-3917] design rxtx_top has port DP driven by constant 0
set_msg_config -new_severity "INFO" -id "Synth 8-3917"
#INFO: [Synth 8-11241] undeclared symbol 'mmcm2_clk1', assumed default net type 'wire' [/home/wirthlin/ee620/520-assignments-wirthlin/mmcm/mmcm_top.sv:150]
set_msg_config -new_severity "ERROR" -id "Synth 8-11241"
#WARNING: [Place 46-29] Timing had been disabled during Placer and, therefore, physical synthesis in Placer will be skipped.
#  For non sequential circuits this message arrives. Ignore it for the labs that do not have sequential circuits.
set_msg_config -new_severity "INFO" -id "Place 46-29"
# Downgrade the following warning. It is given in the regfile lab when no timing constraints are used
# WARNING: [Place 30-2953] Timing driven mode will be turned off because no critical terminals were found.
set_msg_config -new_severity "INFO" -id "Place 30-2953"

# Limit the number of backup log files to zero. This avoids
# creation of multiple backup log files during synthesis and implementation.
set_param general.maxBackupLogs 0