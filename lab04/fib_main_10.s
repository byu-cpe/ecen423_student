#########################################################################
# 
# Filename: fib_main_10.s
#
#########################################################################

.globl  main

# Constant defines for system calls
.eqv PRINT_INT 1
.eqv PRINT_STR 4
.eqv EXIT_CODE 93

# Global data segment
.data
fib_input:				# The location for the input factorial value
	.word 10			# Allocates 4 bytes and sets the input to 10 (arbitrary)

preface_result_str:
	.string "\nFibonacci Number of "

is_str:
	.string " is "

eol_str:				# End of line
	.asciz "\n"

.text

main:

	# Print the Result string preface
	la a0,preface_result_str
	li a7,PRINT_STR			# System call code for print_str
	ecall				
	# Print the input number
	lw a0, fib_input
	li a7,PRINT_INT			# System call code for print_int
	ecall				# Make system call
	# Print "is"
	la a0,is_str
	li a7,PRINT_STR
	ecall

	# Load n into a0 as the argument
	lw a0, fib_input

	# Call the fibonacci function
	jal fibonacci

	# Result is already in a0, just print it
	li a7,PRINT_INT			# System call code for print_int
	ecall				# Make system call
	la a0,eol_str
	li a7,PRINT_STR
	ecall

	# Exit (93) with code 0
	li a0,0
	li a7,EXIT_CODE
	ecall
	ebreak
