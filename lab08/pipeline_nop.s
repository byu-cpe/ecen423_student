###################################################################################
#
# pipeline_nop.s
#
# This assembly language program must be written with the assumption that there is
# is no hazard detection or hardware stalling. All hazards must be resolved by the
# code (i.e., add NOP instructions as needed).
#
# This code assumes the data segment is at 0x2000 and text at 0x0000
# (CompactTextAtZero)
#
# Version V1.2
#  (Note: reflect the version number in the first two instructions)
#
###################################################################################

.text

	# Test immediate instructions
	addi x1, x0, 1		# r1=0+1=1 (0x00000001) positive result
	nop
	nop
	addi x2, x1, -3		# r2=r1-3=1-3=-2 (0xfffffffe) negative result
	nop
	nop
	andi x3, x2, -1		# AND sign extension (r3=r2 AND 0xffffffff=-2) 0xfffffffe
	nop
	nop
	andi x3, x3, 0xff  	# AND no sign extension (r3=r3 AND 0xff=0xfe)
	nop
	nop
	ori, x4, x3, 0x700 	# 0x7fe
	ori, x5, x0, -0x35b	# 0xfffffcaf
	xori x6, x2, -1		# (invert or not) 0x00000001
	slli x7, x2, 0x1  	# 0xfffffffc
	nop
	nop
	srai x8, x7, 0x1  	# 0xfffffffe
	srli x9, x2, 0x1  	# 0x7fffffff
	# Testing x0 register
	addi x0, x0, 1		# x0 should remain 0
	addi x0, x0, 1		# Do add again to make sure x0 did not change
	# Test register instructions
	add x7, x1, x2
	add x8, x3, x1
	add x9, x0, x1
	add x10, x0, x2
	sub x11, x1, x2
	sub x12, x3, x1
	sub x13, x0, x1
	sub x14, x0, x2
	and x15, x2, x3
	or x16, x0, x3
	xor x17, x0, x2
	slt x18, x0, x1
	slt x19, x1, x0
	slt x20, x2, x1
	slt x21, x1, x2
	sll x22, x1, x1 	# 1 << 1 == 2
	srl x23, x2, x1 	# 0xfffffffe >> 1 == 0x7fffffff
	sra x24, x2, x1 	# 0xfffffffe >> 1 == 0xfffffffe
	srl x25, x24, x1 	# 0xfffffffe >> 1 == 0x7fffffff	
	# Load Instructions (data should should be in memory from data segment definitions)
	lw x22, 0(x0)
	lw x23, 4(x0)
	lw x24, 8(x0)
	lw x25, 12(x0)
	addi x26, x0, 16
	nop
	nop
	lw x27, -4(x26)
	lw x28, -8(x26)
	lw x29, -12(x26)
	lw x30, -16(x26)
	# Store Instructions
	sw x1, 0(x0)
	sw x2, 4(x0)
	sw x3, 8(x0)
	sw x4, 12(x0)
	# Check what was written
	lw x22, 0(x0)
	lw x23, 4(x0)
	lw x24, 8(x0)
	lw x25, 12(x0)
	# Place 0x10 (16) in x26 for negative offsets
	addi x26, x0, 16
	nop
	nop
	sw x5, -4(x26)
	sw x6, -8(x26)
	sw x7, -12(x26)
	sw x8, -16(x26)
	# Check what was written
	lw x27, -4(x26)
	lw x28, -8(x26)
	lw x29, -12(x26)
	lw x30, -16(x26)

	# Misc instructions
	addi x1, x0, 1024 		# Add immediate with pos v (x1=0x400)
	addi x2, x0, -1			# Add immediate with neg value: x2 = 0xffffffff (-1)
	ori x3, x0, 0xff		# Basic positive ori : x3 = 0xff
	add x1, x1, x1			# register operation: Double x1 (x1=0x800)
	andi x5, x2, 0xff		# and immediate pos value : x5 = 0xffffffff & 0xff = 0xff
	sub x4, x3, x2			# Subtract : x4 = 0xff - 0xffffffff (255-(-1)) = 256 or 0x100
	add x1, x1, x1			# Add operation: Double x1 : x1 = 0x1000
	slti x6, x3, 0xfe 		# slti : x3 < 0xfe = false, x6=0
	slti x7, x3, 0x101		# slti : x3 < 0x101 = true, x7=1
	addi x0, x0, 1			# make sure you can't write to register 0. x0 = 0
	xori x8, x2, 0x5a		# xor immediate. x8 = 0xffffffff ^ 0x5a = 0xffffffa5
	#
	addi x1, x0, 3
	addi x2, x0, -500
	nop
	nop
	nop

	# Test Branch Instructions
start_beq:
	addi x1, x0, 1		# x1=1
	nop
	nop
	beq x0, x1, skip1	# BEQ not taken
	nop
	nop
	nop
	beq x1, x1, forward	# BEQ taken forward to forward
	# Shouldn't get here
	nop
	nop
	nop
backward:
	beq x5, x5, far_forward	# BEQ taken forward to far_forward
	# Shouldn't get here
	nop
	nop
	nop
far_backward:
	# branch to end
	beq x0, x0, end
	# Shouldn't get here
	nop
	nop
	nop
forward:
	beq x0, x1, start_beq	# BEQ not taken backwards
	nop
	nop
	nop
	beq x1, x1, backward	# BEQ taken backward to backward
	# shouldn't get here.
	# Lots of NOPs to provide a far branch for far_forward
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
far_forward:
	beq x21, x21, far_backward	# far_forward: BEQ taken backward to far_backward
	# Shouldn't get here
	nop
	nop
	nop
end:
	# Do a zero add to all registers to verity the registers are still correct
	addi x0, x0, 0
	addi x1, x1, 0
	addi x2, x2, 0
	addi x3, x3, 0
	addi x4, x4, 0
	addi x5, x5, 0
	addi x6, x6, 0
	addi x7, x7, 0
	addi x8, x8, 0
	addi x9, x9, 0
	addi x10, x10, 0
	addi x11, x11, 0
	addi x12, x12, 0
	addi x13, x13, 0
	addi x14, x14, 0
	addi x15, x15, 0
	addi x16, x16, 0
	addi x17, x17, 0
	addi x18, x18, 0
	addi x19, x19, 0
	addi x20, x20, 0
	addi x21, x21, 0
	addi x22, x22, 0
	addi x23, x23, 0
	addi x24, x24, 0
	addi x25, x25, 0
	addi x26, x26, 0
	addi x27, x27, 0
	addi x28, x28, 0
	addi x29, x29, 0
	addi x30, x30, 0
	addi x31, x31, 0
	nop
	nop
	nop
	ebreak # End of program
	nop
	nop
	nop

skip1:	# Shouldn't get here
	nop
	nop




# .data is at 0x2000
# Only reserving 64 bytes (16 words)
.data
Data:
	.word 0x11111111		# 0x2000
	.word 0x22222222		# 0x2004
	.word 0x33333333		# 0x2008
	.word 0x44444444		# 0x200C
	.word 0x55555555		# 0x2010
	.word 0x66666666		# 0x2014
	.word 0x77777777		# 0x2018
	.word 0xffffffff		# 0x201C
	.word 0x88888888		# 0x2020
	.word 0x99999999		# 0x2024
	.word 0xaaaaaaaa		# 0x2028
	.word 0xbbbbbbbb		# 0x202C
	.word 0xcccccccc		# 0x2030
	.word 0xdddddddd		# 0x2034
	.word 0xeeeeeeee		# 0x2038
	.word 0xa5a55a5a		# 0x203C