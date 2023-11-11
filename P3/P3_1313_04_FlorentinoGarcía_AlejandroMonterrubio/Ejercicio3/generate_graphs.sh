# Variables de archivo
fDAT="mult.dat"
fPNGTime="mult_time.png"
fPNGRead="mult_cache_read.png"
fPNGWrite="mult_cache_write.png"

# Comando para generar gráfica de tiempo de ejecución
gnuplot -e "set title 'Execution Time'; \
set xlabel 'Matrix Size'; \
set ylabel 'Time (seconds)'; \
set term png; \
set output '$fPNGTime'; \
plot '$fDAT' using 1:2 with lines title 'Normal', \
     '$fDAT' using 1:5 with lines title 'Transposed';"

# Comando para generar gráfica de fallos de caché en lectura
gnuplot -e "set title 'Cache Read Misses'; \
set xlabel 'Matrix Size'; \
set ylabel 'Read Misses'; \
set term png; \
set output '$fPNGRead'; \
plot '$fDAT' using 1:3 with lines title 'Normal', \
     '$fDAT' using 1:6 with lines title 'Transposed';"

# Comando para generar gráfica de fallos de caché en escritura
gnuplot -e "set title 'Cache Write Misses'; \
set xlabel 'Matrix Size'; \
set ylabel 'Write Misses'; \
set term png; \
set output '$fPNGWrite'; \
plot '$fDAT' using 1:4 with lines title 'Normal', \
     '$fDAT' using 1:7 with lines title 'Transposed';"
