all: *.c *.h
	gcc -O3  -Wall -I/home/sudarsun/devel/memcached/libevent-2.0.21-stable/libs/include  -D_GNU_SOURCE  *.c -o loader  -L/home/sudarsun/codes/apps/memcached/libevent-2.0.21-stable/libs/lib -levent  -pthread -lm -lrt

clean:
	rm loader
