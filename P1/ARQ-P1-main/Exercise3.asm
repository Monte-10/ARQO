#---------------------------------------------
# Practica 1 - Exercise 2
# Assembler test for testing branch hazards
# Lia Castañeda, Ana Stonek
# 3 effective branches

.data
buffer: .space 16
num0:   .word  1
num1:   .word  2
num2:   .word  4
num3:   .word  8
num4:   .word 16
num5:   .word 32
num6:	.word 7
.text
main:
	#loading
	addi t4, t4, 4  #t4 = 4
	addi t1, t1, 6  #t1 = 6
	addi t2, t2, 7  #t2 = 7
	addi t5, t5, 4	#t5 = 4
	
	#branch effective with r-type hazard
	beq t4, t5, target1 #branch effective
	lw t6, num4		#register  should not be written because next instructions are flushed 
	lw t1, num3		#register  should not be written because next instructions are flushed 
	sub a3, t1, t4 	# t1 - t4 = 2	#register  should not be written because next instructions are flushed 
	addi a2, a0, 2	# a2 = 2	
target1:
	#branch effective with load-use hazard
	lw a5, num6
	beq a5, t2, continue #branch effective 
	addi a3, zero, 5    #register  should not be written because next instructions are flushed 
	add zero, zero, zero
	add zero, zero, zero
	add zero, zero, zero
	add zero, zero, zero
	
continue:
	#branch not effective with load-use hazard
	lw a0, num1
	addi a1, a1, 3
	beq a0, a1, failure		#branch not effective
	
	#branch not effective with r-type hazard
	sub t6, t2, t5
	beq a0, t6, failure		#branch not effective
	beq t6, a1, success		#branch effective
	add zero, zero, zero 	
	add zero, zero, zero
	add zero, zero, zero
	add zero, zero, zero
	add zero, zero, zero
failure:
	add zero, zero, zero	
	
success:
	add zero, zero, zero	
