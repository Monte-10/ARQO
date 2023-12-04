// ----------- Arqo P4-----------------------
// pescalar_par4
//
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include "arqo4.h"

// Definición del umbral (threshold)
#define THRESHOLD 10000 // Puede ajustarse según las pruebas

int main(void)
{
    int nproc;
    float *A = NULL, *B = NULL;
    long long k = 0;
    struct timeval fin, ini;
    double sum = 0;

    A = generateVectorOne(M);
    B = generateVectorOne(M);
    if (!A || !B)
    {
        printf("Error when allocating matrix\n");
        freeVector(A);
        freeVector(B);
        return -1;
    }

    nproc = omp_get_num_procs();
    omp_set_num_threads(nproc);

    printf("Se han lanzado %d hilos.\n", nproc);

    gettimeofday(&ini, NULL);
    /* Bloque de computo */
    sum = 0;

    #pragma omp parallel for if(M > THRESHOLD) reduction(+:sum)
    for (k = 0; k < M; k++)
    {
        sum += A[k] * B[k];
    }
    /* Fin del computo */
    gettimeofday(&fin, NULL);

    printf("Resultado: %f\n", sum);
    printf("Tiempo: %f\n", ((fin.tv_sec * 1000000 + fin.tv_usec) - (ini.tv_sec * 1000000 + ini.tv_usec)) * 1.0 / 1000000.0);
    freeVector(A);
    freeVector(B);

    return 0;
}
