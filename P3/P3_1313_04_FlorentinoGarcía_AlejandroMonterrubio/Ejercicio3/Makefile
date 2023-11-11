LIBS = 
LIB_DIR =  
FLAGS = -O3 -g -Wall -D_GNU_SOURCE

.PHONY: clean all

all: mult_normal mult_trasp

mult_normal: mult_normal.c arqo3.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

mult_trasp: mult_trasp.c arqo3.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

clean:
	rm -f *.o *~ mult_normal mult_trasp
