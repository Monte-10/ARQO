.data
buffer: .space 16   # Reserva 16 bytes de espacio en memoria para 'buffer'
num0:   .word  1    # Declara una palabra (32 bits) en memoria inicializada a 1 para 'num0'
num1:   .word  2    # Declara una palabra (32 bits) en memoria inicializada a 2 para 'num1'
num2:   .word  4    # Declara una palabra (32 bits) en memoria inicializada a 4 para 'num2'
num3:   .word  8    # Declara una palabra (32 bits) en memoria inicializada a 8 para 'num3'
num4:   .word 16    # Declara una palabra (32 bits) en memoria inicializada a 16 para 'num4'
num5:   .word 32    # Declara una palabra (32 bits) en memoria inicializada a 32 para 'num5'

.text
main:
	addi t4, t4, 4  # Añade inmediato: suma 4 a t4 (inicialmente t4 es 0), por lo que t4 queda en 4
	addi t1, t1, 6  # Añade inmediato: suma 6 a t1 (inicialmente t1 es 0), por lo que t1 queda en 6
	addi t2, t2, 7  # Añade inmediato: suma 7 a t2 (inicialmente t2 es 0), por lo que t2 queda en 7
	addi t5, t5, 4	# Añade inmediato: suma 4 a t5 (inicialmente t5 es 0), por lo que t5 queda en 4
	
	add t6, t2, t5  # Suma: añade t2 y t5 y almacena el resultado en t6, por lo que t6 queda en 11
	
	lw t3, num4	   # Carga palabra: carga el contenido de la dirección de 'num4' en t3, por lo que t3 queda en 16
	sub a4, t3, t5	   # Resta: resta t5 de t3 y almacena el resultado en a4, por lo que a4 queda en 12
	
	add t6, t1, t4   # Suma: añade t1 y t4 y almacena el resultado en t6, por lo que t6 queda en 10
	add zero, zero, zero  # Suma que no realiza operación efectiva, mantiene el valor de zero en zero
	add zero, zero, zero  # Otra suma que no realiza operación efectiva, mantiene el valor de zero en zero
	add a5, t6, t5	   # Suma: añade t6 y t5 y almacena el resultado en a5, por lo que a5 queda en 14
