set terminal png size 800,600
set output 'time_slow_fast.png'
set title 'Comparación de tiempos de ejecución - slow vs fast'
set xlabel 'Tamaño de la matriz (N)'
set ylabel 'Tiempo de ejecución (segundos)'
set key left top
set grid
plot 'time_slow_fast_avg.dat' using 1:2 title 'Slow' with linespoints, \
     'time_slow_fast_avg.dat' using 1:3 title 'Fast' with linespoints

