#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#define N 1000 // Ajustar este valor según sea necesario

float **allocate_matrix(int size);
void free_matrix(float **matrix, int size);
void initialize_matrix(float **matrix, int size);

int main() {
    float **A, **B, **C;
    int i, j, k;

    A = allocate_matrix(N);
    B = allocate_matrix(N);
    C = allocate_matrix(N);
    initialize_matrix(A, N);
    initialize_matrix(B, N);

    for(i = 0; i < N; i++) {
        #pragma omp parallel for private(j, k)
        for(j = 0; j < N; j++) {
            C[i][j] = 0.0;
            for(k = 0; k < N; k++) {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
    }

    free_matrix(A, N);
    free_matrix(B, N);
    free_matrix(C, N);

    return 0;
}
