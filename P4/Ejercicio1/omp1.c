// ----------- Arqo P4-----------------------
// Programa que crea hilos utilizando OpenMP
//
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(int argc, char **argv) {
    int i, n = 7;
    omp_set_num_threads(4); // Ejemplo con omp_set_num_threads

    #pragma omp parallel private(i) num_threads(5) // Ejemplo con cláusula num_threads
    {
        int id = omp_get_thread_num();
        int nt = omp_get_num_threads();

        for (i = 0; i < n; i++) {
            printf("Thread %d de %d - Iteración %d\n", id, nt, i);
        }
    }

    return 0;
}
