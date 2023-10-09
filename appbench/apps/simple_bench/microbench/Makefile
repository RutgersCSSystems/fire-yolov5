CC = gcc
CFLAGS = -Wall -pthread -O3
TARGET = private_bench shared_bench

SRCS1 = private_bench.c
SRCS2 = shared_bench.c

all:  private_bench shared_bench

private_bench: $(SRCS1)
	$(CC) $(CFLAGS) -o private_bench $(SRCS1)


shared_bench: $(SRCS2)
	$(CC) $(CFLAGS) -o shared_bench $(SRCS2)


clean:
	rm -f private_bench shared_bench
