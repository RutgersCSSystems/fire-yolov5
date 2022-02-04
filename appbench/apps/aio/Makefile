LIBS=-lrt -lpthread
SIZE=5 ##Test file size in GBs

all:
	gcc read.c -DFILESZ=$(SIZE) -o aio_read $(LIBS)
	gcc write.c -DFILESZ=$(SIZE) -o write
