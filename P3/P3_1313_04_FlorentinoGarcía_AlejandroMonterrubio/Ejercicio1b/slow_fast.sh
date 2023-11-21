declare -A times_slow times_fast

# Inicializa los acumuladores de tiempo
for size in $(seq 1024 1024 16384); do
    times_slow[$size]=0
    times_fast[$size]=0
done

# Ejecuta los programas y acumula los tiempos
for i in $(seq 1 10); do
    for size in $(seq 1024 1024 16384); do
        echo "Ejecutando slow con tamaño $size"
        time_slow=$(./slow $size | grep 'Execution time' | awk '{print $3}')
        times_slow[$size]=$(echo "${times_slow[$size]} + $time_slow" | bc)

        echo "Ejecutando fast con tamaño $size"
        time_fast=$(./fast $size | grep 'Execution time' | awk '{print $3}')
        times_fast[$size]=$(echo "${times_fast[$size]} + $time_fast" | bc)
    done
done

# Calcula los promedios y escribe en un archivo
for size in $(seq 1024 1024 16384); do
    avg_time_slow=$(echo "${times_slow[$size]} / 10" | bc -l)
    avg_time_fast=$(echo "${times_fast[$size]} / 10" | bc -l)
    echo "$size $avg_time_slow $avg_time_fast" >> time_slow_fast_avg.dat
done

