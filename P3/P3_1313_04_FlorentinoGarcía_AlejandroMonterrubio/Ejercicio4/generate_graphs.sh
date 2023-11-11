#!/bin/bash

# Definir los archivos de salida para las gráficas
output_time="execution_times.png"
output_read_misses="cache_read_misses.png"
output_write_misses="cache_write_misses.png"
data_file="cache_study_results.dat"

# Generar la gráfica de tiempos de ejecución
gnuplot << END_GNUPLOT
set title "Execution Times Comparison"
set xlabel "Matrix Size"
set ylabel "Time (seconds)"
set terminal png
set output "$output_time"
set key outside
set grid
plot "$data_file" using 1:5 title 'Normal Execution Time' with linespoints lt rgb "red", \
     "$data_file" using 1:8 title 'Transposed Execution Time' with linespoints lt rgb "blue"
END_GNUPLOT

# Generar la gráfica de fallos de caché de lectura
gnuplot << END_GNUPLOT
set title "Cache Read Misses Comparison"
set xlabel "Matrix Size"
set ylabel "Read Misses"
set terminal png
set output "$output_read_misses"
set key outside
set grid
plot "$data_file" using 1:6 title 'Normal Read Misses' with linespoints lt rgb "red", \
     "$data_file" using 1:9 title 'Transposed Read Misses' with linespoints lt rgb "blue"
END_GNUPLOT

# Generar la gráfica de fallos de caché de escritura
gnuplot << END_GNUPLOT
set title "Cache Write Misses Comparison"
set xlabel "Matrix Size"
set ylabel "Write Misses"
set terminal png
set output "$output_write_misses"
set key outside
set grid
plot "$data_file" using 1:7 title 'Normal Write Misses' with linespoints lt rgb "red", \
     "$data_file" using 1:10 title 'Transposed Write Misses' with linespoints lt rgb "blue"
END_GNUPLOT

echo "Graphs generated: $output_time, $output_read_misses, $output_write_misses"
