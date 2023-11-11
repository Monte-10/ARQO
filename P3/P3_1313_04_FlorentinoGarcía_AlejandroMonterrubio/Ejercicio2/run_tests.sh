#!/bin/bash

# Definir las variables para los tamaños de caché y de matriz
P=4  # P = 4 % 7 = 4
Ninicio=$((1024 + 128 * P))
Nfinal=$((5120 + 128 * P))
Npaso=1024

L2=8388608
Ways=1
BSize=64

Sinicio=1024
Sfinal=8192

# borrar imágenes anteriores
rm -f cache_lectura.png cache_escritura.png

# borrar archivos de datos anteriores
rm -f *.dat

# Bucle para cada tamaño de caché
for ((C = Sinicio; C <= Sfinal; C *= 2)); do
    # Crear un archivo de salida para este tamaño de caché
    output_file="cache_${C}.dat"
    > "$output_file"

    # Bucle para cada tamaño de matriz
    for ((matrix_size = Ninicio; matrix_size <= Nfinal; matrix_size += Npaso)); do
        # Ejecutar y procesar el programa slow y fast
        valgrind --tool=cachegrind --I1=$C,$Ways,$BSize --D1=$C,$Ways,$BSize --LL=$L2,$Ways,$BSize --cachegrind-out-file=slow_out.dat ./slow $matrix_size
        slow_results=$(cg_annotate slow_out.dat | head -n 30 | grep "PROGRAM TOTALS" | awk '{print $9 " " $15}')

        valgrind --tool=cachegrind --I1=$C,$Ways,$BSize --D1=$C,$Ways,$BSize --LL=$L2,$Ways,$BSize --cachegrind-out-file=fast_out.dat ./fast $matrix_size
        fast_results=$(cg_annotate fast_out.dat | head -n 30 | grep "PROGRAM TOTALS" | awk '{print $9 " " $15}')

        echo "$matrix_size $slow_results $fast_results" >> "$output_file"
    done
    sed -i 's/,//g; s/([^)]*)//g' "$output_file"
done

./generate_graphs.sh