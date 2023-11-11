#!/bin/bash

# Ruta completa a los archivos .dat
path_to_dat_files="."

# Tamaños de caché que has utilizado
cache_sizes=(1024 2048 4096 8192)

# Generar las gráficas con Gnuplot
gnuplot <<-EOF
    set title "Fallos de Lectura de Caché"
    set xlabel "Tamaño de la Matriz (N)"
    set ylabel "Fallos de Lectura (D1mr)"
    set grid
    set term png
    set output "cache_lectura.png"
    plot for [C in "${cache_sizes[@]}"] "${path_to_dat_files}/cache_".C.".dat" using 1:2 title 'Slow '.C.'B' with lines, \
         for [C in "${cache_sizes[@]}"] "${path_to_dat_files}/cache_".C.".dat" using 1:4 title 'Fast '.C.'B' with lines
EOF

gnuplot <<-EOF
    set title "Fallos de Escritura de Caché"
    set xlabel "Tamaño de la Matriz (N)"
    set ylabel "Fallos de Escritura (D1mw)"
    set grid
    set term png
    set output "cache_escritura.png"
    plot for [C in "${cache_sizes[@]}"] "${path_to_dat_files}/cache_".C.".dat" using 1:3 title 'Slow '.C.'B' with lines, \
         for [C in "${cache_sizes[@]}"] "${path_to_dat_files}/cache_".C.".dat" using 1:5 title 'Fast '.C.'B' with lines
EOF
