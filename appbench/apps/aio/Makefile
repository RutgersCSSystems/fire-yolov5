LIBS=-lrt -lpthread
SIZE=5 ##Test file size in GBs

all:
	gcc read.c -DFILESZ=$(SIZE) -o read_onlyospfetch $(LIBS)
	gcc read.c -DFILESZ=$(SIZE) -DONLYAPP -o read_noprefetch $(LIBS)
	gcc read.c -DFILESZ=$(SIZE) -DONLYAPP -DAIO_PREFETCH -o read_onlyaiopfetch $(LIBS)
	gcc read.c -DFILESZ=$(SIZE) -DAIO_PREFETCH -o read_os_aiopfetch $(LIBS)
	gcc read.c -DFILESZ=$(SIZE) -DAIO_PREFETCH -DDONT_READ_FILE -o dont_read_os_aiopfetch $(LIBS)
	gcc write.c -DFILESZ=$(SIZE) -o write
