.data
buffer: .space 16   # Reserva 16 bytes de espacio en memoria para 'buffer'
num0:   .word  1    # Declara una palabra (32 bits) en memoria inicializada a 1 para 'num0'
num1:   .word  2    # Declara una palabra (32 bits) en memoria inicializada a 2 para 'num1'
num2:   .word  4    # Declara una palabra (32 bits) en memoria inicializada a 4 para 'num2'
num3:   .word  8    # Declara una palabra (32 bits) en memoria inicializada a 8 para 'num3'
num4:   .word 16    # Declara una palabra (32 bits) en memoria inicializada a 16 para 'num4'
num5:   .word 32    # Declara una palabra (32 bits) en memoria inicializada a 32 para 'num5'
num6:   .word 7     # Declara una palabra (32 bits) en memoria inicializada a 7 para 'num6'

.text
main:
	addi t4, t4, 4  # Suma inmediata: establece t4 a 4
	addi t1, t1, 6  # Suma inmediata: establece t1 a 6
	addi t2, t2, 7  # Suma inmediata: establece t2 a 7
	addi t5, t5, 4  # Suma inmediata: establece t5 a 4
	
	# Rama efectiva con peligro de tipo R (hazard)
	beq t4, t5, target1 # Si t4 es igual a t5, salta a la etiqueta target1 (Debería haber forwarding de t5)
	lw t6, 0(t0)       # Carga una palabra de memoria en t6 desde la dirección apuntada por t0
	lw t1, 0(t0)       # Carga una palabra de memoria en t1 desde la dirección apuntada por t0
	sub a3, t1, t4     # Resta t4 de t1 y almacena el resultado en a3
	addi a2, a0, 2     # Suma inmediata: establece a2 a 2 (presumiendo que a0 estaba inicialmente en 0)
target1:
	# Rama efectiva con peligro de uso de carga (load-use hazard)
	lw a5, num6       # Carga el valor de 'num6' (7) en a5
	beq a5, t2, continue # Si a5 es igual a t2, salta a la etiqueta continue
	# Las siguientes instrucciones son NOPs (no operation) que no tienen efecto práctico
	add zero, zero, zero
	add zero, zero, zero
	add zero, zero, zero
	add zero, zero, zero
	add zero, zero, zero
	
continue:
	# Rama no efectiva con peligro de uso de carga (load-use hazard)
	lw a0, num1         # Carga el valor de 'num1' (2) en a0
	addi a1, a1, 3      # Suma inmediata: establece a1 a 3 (presumiendo que a1 estaba inicialmente en 0)
	beq a0, a1, failure # Si a0 es igual a a1, salta a la etiqueta failure
	
	# Rama no efectiva con peligro de tipo R (hazard)
	sub t6, t2, t5      # Resta t5 de t2 y almacena el resultado en t6
	beq a0, t6, failure # Si a0 es igual a t6, salta a la etiqueta failure
	beq t6, a1, success # Si t6 es igual a a1, salta a la etiqueta success
	# Las siguientes instrucciones son NOPs (no operation) que no tienen efecto práctico
	add zero, zero, zero
	add zero, zero, zero
	add zero, zero, zero
	add zero, zero, zero
	add zero, zero, zero
failure:
	add zero, zero, zero	# NOP en la etiqueta failure
	
success:
	add zero, zero, zero	# NOP en la etiqueta success
