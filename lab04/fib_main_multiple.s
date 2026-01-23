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
.eqv MAX_FIB 25

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

	# Initialize the current Fibonacci input value to 0
	la t0, fib_input
	sw x0, 0(t0)

	# Loop for executing a Fibonacci calculation
fib_loop:
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

	# Increment the Fibonacci input value
	lw t0, fib_input
	addi t0, t0, 1
	li t1, MAX_FIB
	# Exit loop if max reached
	blt t1, t0, exit

	# save updated input value
	la t1, fib_input
	sw t0, 0(t1)

	j fib_loop

exit:
	# Exit (93) with code 0
	li a0,0
	li a7,EXIT_CODE
	ecall
	ebreak
