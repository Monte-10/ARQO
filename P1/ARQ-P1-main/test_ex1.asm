
#---------------------------------------------
# Practica 1 - Exercise 2
# Assembler test for testing particularly j and andi
# Lia Castañeda, Ana Stonek

.data
buffer: .space 16
num0:   .word  1
num1:   .word  2
num2:   .word  4
num3:   .word  8
num4:   .word 16
num5:   .word 32

.text
main:
	#loading
	addi t4, t4, 4  #t4 = 4
	addi t1, t1, 6  #t1 = 6
	addi t2, t2, 7  #t2 = 7
	addi t5, t5, 4	#t5 = 4
	
	add t6, t2, t5 #result = 11
	
	#load-use hazard
	lw t3, num4	#t3 = 16
	sub a4, t3, t5	#a4 = 12
	
	#internal forwarding (inside registry bank)
	add t6, t1, t4	#t6 = 10
	add zero, zero, zero
	add zero, zero, zero
	add a5, t6, t5	#a5 = 14
	


#TODO: case Not effective (Forwarding)
#TODO: case effective (Load Hazard)
#TODO: case not effective (Load Hazard) 