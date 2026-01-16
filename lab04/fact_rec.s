#########################################################################
#
# Filename: fact_rec.s
# 
# Author: Mike Wirthlin
#
# Description: Function to calculate the factorial for given 
# non-zero, non-negative integer input (output = input!) with system calls 
# and subroutine that utilizes the stack through recursion
#
# Functions:
#  - fact_func: Performs factorial for input a0 (a0!) and returns result to a0
#
#########################################################################


# The function name is 'fact_rec' and we need to make it global so the
# main function can call it.
.globl  fact_rec

# The function needs to be in the text segment
.text

fact_rec:			# Performs factorial for input a0 (a0!) and returns result to a0

	addi sp, sp, -8		# fact_rec: Make room to save values on the stack
	sw s0, 0(sp)		# Save the caller s0 on stack. Used as the subroutine factorial operand
	sw ra, 4(sp)		# The return address needs to be saved to know where subroutine was called from 

	mv s0, a0		# Save the argument into s0 (Used to compute the next factorial operand)

	bgtz a0,$L2		# Branch if input > 0 there are additional factorial operands that still needs to be stored
	li a0,1			# Return 1, input must be 0 so set the operand to 1 since input = 0, result = 1
	j $L1			# Jump to code to return (end of recursion)

$L2:
	addi a0,a0,-1		# Compute n - 1
	jal fact_rec		# Call factorial function to store next factorial operand, argument (a0 (input)) return value (a0)
	mul a0,a0,s0		# All factorial operands have been stored, multiple current stored operand and
				# return operand to Compute fact(input-1) * input 

$L1:    
	lw s0, 0(sp)		# Restore any callee saved regs used. Load previous callee factorial operand
	lw ra, 4(sp)		# Restore return address
	addi sp, sp, 8		# Update stack pointer

	ret			# Jump to return address
