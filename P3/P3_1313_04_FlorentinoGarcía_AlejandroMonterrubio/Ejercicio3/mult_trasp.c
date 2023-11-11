#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#include "arqo3.h"

void compute(tipo **a, tipo **b, tipo **c, int n);
tipo **transposeMatrix(tipo **b, int n); // Asumimos que existe en arqo3.c

int main(int argc, char *argv[]) {
    int n;
    tipo **a = NULL;
    tipo **b = NULL;
    tipo **c = NULL;
    struct timeval fin, ini;

    printf("Word size: %ld bits\n", 8 * sizeof(tipo));

    if (argc != 2) {
        printf("Error: ./%s <matrix size>\n", argv[0]);
        return -1;
    }
    n = atoi(argv[1]);
    a = generateMatrix(n);
    b = generateMatrix(n);
    c = generateEmptyMatrix(n);
    if (!a || !b || !c) {
        printf("Error: Out of memory\n");
        return -1;
    }

    gettimeofday(&ini, NULL);

    /* Main computation */
    b = transposeMatrix(b, n); // Trasponemos la matriz b
    compute(a, b, c, n);
    /* End of computation */

    gettimeofday(&fin, NULL);
    printf("Execution time: %f\n", ((fin.tv_sec * 1000000 + fin.tv_usec) - (ini.tv_sec * 1000000 + ini.tv_usec)) * 1.0 / 1000000.0);

    freeMatrix(a);
    freeMatrix(b); // Asumimos que b ahora apunta a la matriz traspuesta y debe ser liberada
    freeMatrix(c);
    return 0;
}

void compute(tipo **a, tipo **b, tipo **c, int n) {
    int i, j, k;

    for (i = 0; i < n; i++) {
        for (j = 0; j < n; j++) {
            c[i][j] = 0;
            for (k = 0; k < n; k++) {
                c[i][j] += a[i][k] * b[j][k]; // Usando el nuevo orden de índices para la matriz traspuesta
            }
        }
    }
}

// Esta es una función ficticia, la real debe estar implementada en arqo3.c y disponible en arqo3.h
tipo **transposeMatrix(tipo **b, int n) {
    // Implementa la transposición aquí o asegúrate de que está disponible en arqo3.c
    return b; // Esto es solo un marcador de posición
}

