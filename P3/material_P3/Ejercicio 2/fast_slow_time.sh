#!/bin/bash

# inicializar variables
P=4
Ninicio=$((1024 + 128 * P))
Npaso=1024
Nfinal=$((5120 + 128 * P))
Sinicio=1024
Sfinal=8192
L2=8388608
Ways=1
BSize=64
fPNG1=cache_lectura.png
fPNG2=cache_escritura.png

# borrar imágenes anteriores
rm -f $fPNG1 $fPNG2

# borrar archivos de datos anteriores
rm -f cache_*.dat

echo "Running slow and fast for different cache sizes..."

for ((S = Sinicio ; S <= Sfinal ; S *= 2)); do
    echo "Cache size: $S"
    fDAT=cache_${S}.dat
    touch $fDAT

    for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
        echo "Matrix size: $N"

        valgrind --tool=cachegrind --I1=$S,$Ways,$BSize --D1=$S,$Ways,$BSize --LL=$L2,$Ways,$BSize --cachegrind-out-file=slow_cachegrind.out ./slow $N
        valgrind --tool=cachegrind --I1=$S,$Ways,$BSize --D1=$S,$Ways,$BSize --LL=$L2,$Ways,$BSize --cachegrind-out-file=fast_cachegrind.out ./fast $N

        D1mr_slow=$(cg_annotate slow_cachegrind.out | grep 'D1mr' | awk '{print $5}' | tr -d ',')
        D1mw_slow=$(cg_annotate slow_cachegrind.out | grep 'D1mw' | awk '{print $8}' | tr -d ',')

        D1mr_fast=$(cg_annotate fast_cachegrind.out | grep 'D1mr' | awk '{print $5}' | tr -d ',')
        D1mw_fast=$(cg_annotate fast_cachegrind.out | grep 'D1mw' | awk '{print $8}' | tr -d ',')

        echo "$N $D1mr_slow $D1mw_slow $D1mr_fast $D1mw_fast" >> $fDAT
    done

    # Eliminar comas para evitar errores en gnuplot
    sed -i 's/,//g' $fDAT
done

echo "Generating plots..."

# Función para generar la gráfica para los fallos de lectura y escritura
generate_plot() {
    local output=$1
    local title=$2
    local ylabel=$3
    local col_index=$4

    gnuplot << END_GNUPLOT
set title "$title"
set xlabel "Matrix Size (N)"
set ylabel "$ylabel"
set term png
set output "$output"
plot for [i=1024:8192:1024] 'cache_'.i.'.dat' using 1:((\$$col_index)*2) with linespoints title 'slow '.i.'B', \
     for [i=1024:8192:1024] 'cache_'.i.'.dat' using 1:((\$$col_index)*2+1) with linespoints title 'fast '.i.'B'
quit
END_GNUPLOT
}

# Generar gráficos para fallos de lectura y escritura
generate_plot $fPNG1 "Data Read Misses" "Cache read misses (D1mr)" 2
generate_plot $fPNG2 "Data Write Misses" "Cache write misses (D1mw)" 3

# Limpieza de archivos temporales
rm -f *_cachegrind.out

