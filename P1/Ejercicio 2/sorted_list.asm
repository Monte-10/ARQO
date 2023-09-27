.data
original_list: .word 34, 12, 56, 78, 9, 45, 23, 67, 89, 1
sorted_list:   .space 40  # Reservamos espacio para 10 enteros

.text
main:
    # Inicializamos los registros
    la a0, original_list   # Dirección inicial de la lista original
    la a1, sorted_list     # Dirección inicial de la lista ordenada
    li a2, 10              # Contador para la longitud de la lista

    # Copiamos la lista original a la lista ordenada
copy_loop:
    lw a3, 0(a0)           # Cargamos el valor en a3
    sw a3, 0(a1)           # Guardamos el valor en la lista ordenada
    addi a0, a0, 4         # Avanzamos a la siguiente posición en la lista original
    addi a1, a1, 4         # Avanzamos a la siguiente posición en la lista ordenada
    addi a2, a2, -1        # Decrementamos el contador
    bnez a2, copy_loop     # Si el contador no es cero, repetimos el bucle

    # Realizamos la ordenación de burbuja
    li a4, 9               # Contador externo para el bucle de burbuja
outer_loop:
    li a5, 0               # Contador interno para el bucle de burbuja
    la a1, sorted_list     # Reseteamos la dirección inicial de la lista ordenada para el bucle interno
inner_loop:
    lw a6, 0(a1)           # Cargamos el valor actual en a6
    lw a7, 4(a1)           # Cargamos el siguiente valor en a7
    ble a6, a7, skip_swap  # Si el valor actual es menor o igual al siguiente, saltamos al intercambio

    # Intercambiamos los valores
    sw a7, 0(a1)
    sw a6, 4(a1)

skip_swap:
    addi a1, a1, 4         # Avanzamos a la siguiente posición en la lista ordenada
    addi a5, a5, 1         # Incrementamos el contador interno
    blt a5, a4, inner_loop # Si el contador interno es menor que el contador externo, repetimos el bucle interno

    addi a4, a4, -1        # Decrementamos el contador externo
    bnez a4, outer_loop    # Si el contador externo no es cero, repetimos el bucle externo

    # Terminamos el programa
    li a7, 10
    ecall
