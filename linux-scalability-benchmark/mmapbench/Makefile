CC=gcc
CFLAGS=-O2 -Wall -pthread -D_ANONMEM

default: mmapbench

forkbench: mmapbench.o
	$(CC) -o $@ $^ $(CFLAGS)

clean:
	rm -rf *.o
	rm -rf mmapbench
