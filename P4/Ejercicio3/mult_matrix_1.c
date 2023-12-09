#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#include "arqo3.h"

void compute(tipo **a, tipo **b, tipo **c, int n);

int main( int argc, char *argv[])
{
	int n;
	tipo **a=NULL;
	tipo **b=NULL;
	tipo **c=NULL;
	struct timeval fin,ini;

	printf("Word size: %ld bits\n",8*sizeof(tipo));

	if( argc!=2 )
	{
		printf("Error: ./%s <matrix size>\n", argv[0]);
		return -1;
	}
	n=atoi(argv[1]);
	a=generateMatrix(n);
	b=generateMatrix(n);
	c=generateEmptyMatrix(n);
	if( !a || !b || !c )
	{
		freeMatrix(a);
		freeMatrix(b);
		freeMatrix(c);
		return -1;
	}


	
	gettimeofday(&ini,NULL);

	/* Main computation */
	compute(a,b,c,n);
	/* End of computation */

	gettimeofday(&fin,NULL);
	printf("Execution time: %f\n", ((fin.tv_sec*1000000+fin.tv_usec)-(ini.tv_sec*1000000+ini.tv_usec))*1.0/1000000.0);
	


	freeMatrix(a);
	freeMatrix(b);
	freeMatrix(c);
	return 0;
}


void compute(tipo **a, tipo **b, tipo **c, int n)
{
    int i,j,k;
    tipo sum;

    for(i=0;i<n;i++)
    {
        for(j=0;j<n;j++)
        {
            sum = 0;
            #pragma omp parallel for reduction(+:sum) shared(a,b,n,i,j)
            for(k=0;k<n;k++)
            {
                sum += a[i][k] * b[k][j];
            }
            c[i][j] = sum;
        }
    }
}
