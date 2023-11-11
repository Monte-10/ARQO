#!/bin/bash

P=4 # Este valor deberá ser ajustado al número proporcionado por el ejercicio.
Ninicio=$((128 + 16 * P))
Npaso=256
Nfinal=$((2176 + 16 * P))
fDAT=mult.dat
fPNG1=mult_cache_read.png
fPNG2=mult_cache_write.png
fPNG3=mult_time.png
Rep=10

# borrar el fichero DAT y los ficheros PNG
rm -f $fDAT $fPNG1 $fPNG2 $fPNG3

# generar el fichero DAT vacío
touch $fDAT

echo "Running normal and transposed..."
# bucle para N desde inicio hasta final
for ((N = Ninicio; N <= Nfinal ; N += Npaso)); do
	echo "N: $N / $Nfinal..."

	# Inicializar acumuladores
	normalTime=0
	transposedTime=0
	normalReadMisses=0
	normalWriteMisses=0
	transposedReadMisses=0
	transposedWriteMisses=0
	
	# bucle de repeticiones
	for ((i = 1; i <= Rep; i++)); do
		# Ejecutar normal y transposed y acumular tiempos
		normalTime=$(./mult_normal $N | grep 'Execution time' | awk '{print $3}')
		transposedTime=$(./mult_trasp $N | grep 'Execution time' | awk '{print $3}')
		normalTimeTotal=$(awk "BEGIN {print $normalTimeTotal+$normalTime}")
		transposedTimeTotal=$(awk "BEGIN {print $transposedTimeTotal+$transposedTime}")
	done
	
	# Calcular la media de los tiempos
	normalTimeAvg=$(awk "BEGIN {print $normalTimeTotal/$Rep}")
	transposedTimeAvg=$(awk "BEGIN {print $transposedTimeTotal/$Rep}")

	# Ejecutar cachegrind
	valgrind --tool=cachegrind --cachegrind-out-file=normal_out.dat ./mult_normal $N
	valgrind --tool=cachegrind --cachegrind-out-file=transposed_out.dat ./mult_trasp $N

	# Recoger fallos de caché
	normalReadMisses=$(cg_annotate normal_out.dat | grep 'PROGRAM TOTALS' | awk '{print $9}')
	normalWriteMisses=$(cg_annotate normal_out.dat | grep 'PROGRAM TOTALS' | awk '{print $15}')
	transposedReadMisses=$(cg_annotate transposed_out.dat | grep 'PROGRAM TOTALS' | awk '{print $9}')
	transposedWriteMisses=$(cg_annotate transposed_out.dat | grep 'PROGRAM TOTALS' | awk '{print $15}')


	# Escribir datos en mult.dat
	echo "$N $normalTimeAvg $normalReadMisses $normalWriteMisses $transposedTimeAvg $transposedReadMisses $transposedWriteMisses" >> $fDAT
done

# Formatear mult.dat para eliminar comas
sed -i 's/,//g' $fDAT

./generate_graphs.sh