#########################################################################
#
# Filename: fact_rec_main.s
# 
# Author: Mike Wirthlin
#
# Description: Main function for fact_rec.s to calculate the factorial for given
#
#########################################################################


.globl  main

# Constant defines for system calls
.eqv PRINT_INT 1
.eqv PRINT_STR 4
.eqv READ_INT 5
.eqv EXIT_CODE 93


# Global data segment
.data
input:				# The location for the input factorial value
	.word 6			# Allocates 4 bytes and sets the input to 6 (arbitrary)
	
output:				# The location for the output calculated factorial
				# value given the input value data
	.word 0			# Allocates 4 bytes and sets the output to 0 for initialization

input_str:
	.asciz "Input Value: "
	
result_str:			# The location for the result string data
	.asciz "! = "		# allocates 1 byte per character plus null character

eol_str:			# End of line
	.asciz "\n"             

.text
main:				# Label for start of program

# Print the input prompt
	la a0,input_str
	li a7,PRINT_STR
	ecall
	# System call to read integer input from user
	li a7,READ_INT
	ecall			# Result is in a0
	la t0, input		# Load address of input
	sw a0, 0(t0)		# Store the user input (a0) value into memory

	lw a0,input		# Loads the desired input value from memory to compute the factorial
	jal fact_rec		# Jump and link (save return address) to factorial subroutine (function), argument (a0 (input)) return value 
	la t0,output		# Load output address to t0
	sw a0,0(t0)		# Save the calculated factorial result to output memory location
	
exit:				# The factorial has finished computing, perform system calls to print
				# result and waits on debug breakpoint
	lw a0,input		# Load Input value into a0 to be printed
	li a7,PRINT_INT		# System call code for print_int code 1
	ecall			# Make system call
		

	la a0,result_str	# Put result_str address in a0 to be printed
	li a7,PRINT_STR		# System call code for print_str code 4
	ecall			# Make system call
 
	lw a0,output		# Load output value into a0 to be printed
	li a7,PRINT_INT		# System call code for print_int code 1
	ecall			# Make system call

	la a0,eol_str		# Put end of line
	li a7,PRINT_STR		# System call code for print_str code 4
	ecall			# Make system call (i.e., print string)
	
	li a0,0			# Exit (93) with code 0
	li a7,EXIT_CODE		# System call value
	ecall			# Make system call
	ebreak			# Finish with breakpoint

# The fact_rec subrouting is defined in the file 'fact_rec.s'
