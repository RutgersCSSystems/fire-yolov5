CC=mpicc
LIBS=-L/usr/local/lib -lm -lmpi

FLAGS=-D SYSTEM -D COLUMBIA -D IO

all:
	$(CC) $(FLAGS) -o MADbench2_io MADbench2.c $(LIBS)

clean:
	rm -rf MADbench2_io

