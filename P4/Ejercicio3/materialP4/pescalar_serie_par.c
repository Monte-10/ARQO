#include <stdio.h>
#include <stdlib.h>
#include "arqo4.h"

#define N 1000  // Tamaño de la matriz

int main(void) {
    float **A = NULL, **B = NULL, **C = NULL;
    int i, j, k;
    struct timeval fin, ini;

    A = generateMatrix(N);  // Suponiendo que genera una matriz de NxN
    B = generateMatrix(N);
    C = generateEmptyMatrix(N);  // Suponiendo que genera una matriz vacía de NxN

    if (!A || !B || !C) {
        printf("Error when allocating matrices\n");
        return -1;
    }

    gettimeofday(&ini, NULL);
    /* Bloque de cálculo */
    for (i = 0; i < N; i++) {
        for (j = 0; j < N; j++) {
            C[i][j] = 0;
            for (k = 0; k < N; k++) {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
    }
    /* Fin del cálculo */
    gettimeofday(&fin, NULL);

    printf("Tiempo: %f\n", ((fin.tv_sec * 1000000 + fin.tv_usec) - (ini.tv_sec * 1000000 + ini.tv_usec)) * 1.0 / 1000000.0);

    freeMatrix(A);  // Suponiendo que libera la memoria de una matriz
    freeMatrix(B);
    freeMatrix(C);

    return 0;
}
