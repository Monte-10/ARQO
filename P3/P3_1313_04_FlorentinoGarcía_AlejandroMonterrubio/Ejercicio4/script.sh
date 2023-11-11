#!/bin/bash

# Definir los tamaños de caché, la asociatividad y los tamaños de línea de caché a probar
cache_sizes=(32768 65536 131072)  # Tamaños de caché en bytes
associativities=(1 2 4 8)  # Niveles de asociatividad
line_sizes=(64 128)  # Tamaños de línea de caché en bytes
matrix_sizes=(256 512 1024)  # Tamaños de matriz

# Archivo para almacenar los resultados
output_file="cache_study_results.dat"
echo "MatrixSize CacheSizeBytes Associativity LineSizeBytes NormalTime NormalReadMisses NormalWriteMisses TransposedTime TransposedReadMisses TransposedWriteMisses" > "$output_file"

# Bucle para probar cada configuración de caché
for cache_size in "${cache_sizes[@]}"; do
    for associativity in "${associativities[@]}"; do
        for line_size in "${line_sizes[@]}"; do
            for matrix_size in "${matrix_sizes[@]}"; do
                echo "Matrix Size: $matrix_size, Cache Size: ${cache_size}B, Associativity: $associativity, Line Size: ${line_size}B"
                
                # Ejecutar y procesar el programa normal
                normal_time=$(./mult_normal $matrix_size | grep 'Execution time' | awk '{print $3}')
                valgrind --tool=cachegrind --I1=${cache_size},${associativity},${line_size} \
                         --D1=${cache_size},${associativity},${line_size} \
                         --LL=8388608,1,64 \
                         --cachegrind-out-file=normal_cache.out ./mult_normal $matrix_size
                normalReadMisses=$(cg_annotate normal_cache.out | grep 'PROGRAM TOTALS' | awk '{print $9}')
                normalWriteMisses=$(cg_annotate normal_cache.out | grep 'PROGRAM TOTALS' | awk '{print $15}')
                
                # Ejecutar y procesar el programa transposed
                transposed_time=$(./mult_trasp $matrix_size | grep 'Execution time' | awk '{print $3}')
                valgrind --tool=cachegrind --I1=${cache_size},${associativity},${line_size} \
                         --D1=${cache_size},${associativity},${line_size} \
                         --LL=8388608,1,64 \
                         --cachegrind-out-file=transposed_cache.out ./mult_trasp $matrix_size
                transposedReadMisses=$(cg_annotate transposed_cache.out | grep 'PROGRAM TOTALS' | awk '{print $9}')
                transposedWriteMisses=$(cg_annotate transposed_cache.out | grep 'PROGRAM TOTALS' | awk '{print $15}')
                
                # Añadir los resultados al archivo de salida
                echo "$matrix_size $cache_size $associativity $line_size $normal_time $normalReadMisses $normalWriteMisses $transposed_time $transposedReadMisses $transposedWriteMisses" >> "$output_file"
            done
        done
    done
    sed -i 's/,//g' "$output_file"
done

# Crear gráficos con GNUplot
./generate_graphs.sh