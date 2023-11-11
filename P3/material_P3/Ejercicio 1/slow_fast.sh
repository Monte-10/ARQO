for size in $(seq 1024 1024 16384); do
    for i in $(seq 1 10); do
        echo "Ejecutando slow con tamaño $size"
        time_slow=$(./slow $size | grep 'Execution time' | awk '{print $3}')
        echo "Ejecutando fast con tamaño $size"
        time_fast=$(./fast $size | grep 'Execution time' | awk '{print $3}')
        echo "$size $time_slow $time_fast" >> time_slow_fast.dat
    done
done
