LIBS=-lrt -lpthread
SIZE=5 ##Test file size in GBs
NR_RA_PG=40 ##Nr of pages to prefetch in one req
NR_BG_THREADS=1
BIN_DIR=./bin

FLAGS=-DFILESZ=$(SIZE) -DNR_RA_PAGES=$(NR_RA_PG) -DNR_BG_THREADS=$(NR_BG_THREADS)

all: read.c utils/thpool.c
	gcc $^ $(FLAGS) -o $(BIN_DIR)/read_onlyospfetch $(LIBS)
	gcc $^ $(FLAGS) -DNR_RA_PAGES=$(NR_RA_PG) -o $(BIN_DIR)/read_noprefetch $(LIBS)
	gcc $^ $(FLAGS) -DONLYAPP -DPREFETCH -DPREFETCH_READAHEAD -o $(BIN_DIR)/read_onlypfetch $(LIBS)
	gcc $^ $(FLAGS) -DPREFETCH -DPREFETCH_READAHEAD -o $(BIN_DIR)/read_os_smallpfetch $(LIBS)
	gcc $^ $(FLAGS) -DPREFETCH -DPREFETCH_READ -o $(BIN_DIR)/read_os_smallpfetch_read $(LIBS)
	gcc $^ $(FLAGS) -DPREFETCH -DPREFETCH_PREAD_RA -o $(BIN_DIR)/read_os_smallpfetch_preadra $(LIBS)
	gcc $^ $(FLAGS) -DDONT_READ_FILE -DPREFETCH -DPREFETCH_PREAD_RA -o $(BIN_DIR)/dont_read_os_smallpfetch_preadra $(LIBS)
	gcc $^ $(FLAGS) -DPREFETCH -DFULL_RA -DPREFETCH_READAHEAD -o $(BIN_DIR)/read_os_fullpfetch $(LIBS)
	gcc $^ $(FLAGS) -DPREFETCH -DDONT_READ_FILE -DPREFETCH_READAHEAD -o $(BIN_DIR)/dont_read_os_pfetch $(LIBS)
	gcc write.c $(FLAGS) -o $(BIN_DIR)/write
