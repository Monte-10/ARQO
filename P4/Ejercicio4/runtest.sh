#!/bin/bash

# Definimos el número de ejecuciones para calcular el tiempo medio
NUM_EXECUTIONS=5

# Archivo de salida para los tiempos
TIME_FILE="tiempos.csv"
echo "Version,Tiempo" > $TIME_FILE

# Función para calcular el tiempo medio de las ejecuciones
function calculate_average_time() {
    local program=$1
    local total_time=0
    local execution_time
    local average_time

    for (( i=1; i<=NUM_EXECUTIONS; i++ ))
    do
        execution_time=$($program | grep 'Tiempo' | awk '{print $2}')
        total_time=$(echo "$total_time + $execution_time" | bc -l)
    done

    average_time=$(echo "$total_time / $NUM_EXECUTIONS" | bc -l)
    echo "${program#./},$average_time" >> $TIME_FILE
}

# Array de programas para ejecutar
programs=(./pi_serie ./pi_par1 ./pi_par2 ./pi_par3 ./pi_par4 ./pi_par5 ./pi_par6 ./pi_par7)

# Ejecutamos cada programa y calculamos el tiempo medio
for program in "${programs[@]}"
do
    calculate_average_time "$program"
done

# Generamos la gráfica de tiempos usando GNUPlot
gnuplot <<- EOF
    set datafile separator ","
    set title "Tiempo de ejecución de cada versión de PI"
    set xlabel "Versión"
    set ylabel "Tiempo (s)"
    set yrange [0:]
    set grid
    set style data histograms
    set style histogram cluster gap 1
    set style fill solid border -1
    set boxwidth 0.5
    set term png
    set output "tiempos.png"
    plot "tiempos.csv" using 2:xtic(1) title 'Tiempo de ejecución'
EOF

echo "Gráfica generada como tiempos.png"
