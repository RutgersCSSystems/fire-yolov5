CC=mpicc.mpich
LIBS=-L/usr/local/lib -lm -lmpi

FLAGS=-D SYSTEM -D COLUMBIA -D IO
#FLAGS=-D SYSTEM -D COLUMBIA -D IO -D COMPUTE ##This enables compute -> makes compute time >> system time
#ifdef W_WRITE 

all:
	$(CC) $(FLAGS) -g -o MADbench2_io MADbench2.c $(LIBS)

clean:
	rm -rf MADbench2_io
