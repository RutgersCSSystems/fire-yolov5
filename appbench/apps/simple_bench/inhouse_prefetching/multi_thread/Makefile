LIBS=-lrt -lpthread
SIZE=5 ##Test file size in GBs
NR_RA_PG=40 ##Nr of pages to prefetch in one req
NR_BG_THREADS=1
BIN_DIR=./bin

FLAGS=-DFILESZ=$(SIZE) -DNR_RA_PAGES=$(NR_RA_PG) -DNR_BG_THREADS=$(NR_BG_THREADS)
APP_PREFETCH=-DCONCURRENT_PREFETCH
ONLYAPP_PREFETCH=-DONLYAPP $(APP_PREFETCH)

all: write read_os read_noos test

read_os: read.c utils/thpool.c
	gcc $^ $(FLAGS) $(APP_PREFETCH) -DPREFETCH_READAHEAD -o $(BIN_DIR)/read_os_smallpfetch $(LIBS)
	gcc $^ $(FLAGS) $(APP_PREFETCH) -DPREFETCH_READ -o $(BIN_DIR)/read_os_smallpfetch_read $(LIBS)
	gcc $^ $(FLAGS) $(APP_PREFETCH) -DPREFETCH_PREAD_RA -DREAD_PG_PREAD_RA=1 -o $(BIN_DIR)/read_os_smallpfetch_preadra_1 $(LIBS)
	gcc $^ $(FLAGS) $(APP_PREFETCH) -DPREFETCH_PREAD_RA -DREAD_PG_PREAD_RA=0 -o $(BIN_DIR)/read_os_smallpfetch_preadra_0 $(LIBS)
	gcc $^ $(FLAGS) $(APP_PREFETCH) -DFULL_RA -DPREFETCH_READAHEAD -o $(BIN_DIR)/read_os_fullpfetch $(LIBS)
	gcc $^ $(FLAGS) $(APP_PREFETCH) -DDONT_READ_FILE -DPREFETCH_READAHEAD -o $(BIN_DIR)/dont_read_os_pfetch $(LIBS)
	gcc $^ $(FLAGS) -DPREAD_RA -o $(BIN_DIR)/preadra_os_seq $(LIBS)

read_noos: read.c utils/thpool.c
	gcc $^ $(FLAGS) $(ONLYAPP_PREFETCH) -DPREFETCH_READAHEAD -o $(BIN_DIR)/read_noos_smallpfetch $(LIBS)
	gcc $^ $(FLAGS) $(ONLYAPP_PREFETCH) -DPREFETCH_READ -o $(BIN_DIR)/read_noos_smallpfetch_read $(LIBS)
	gcc $^ $(FLAGS) $(ONLYAPP_PREFETCH) -DPREFETCH_PREAD_RA -o $(BIN_DIR)/read_noos_smallpfetch_preadra $(LIBS)
	gcc $^ $(FLAGS) $(ONLYAPP_PREFETCH) -DFULL_RA -DPREFETCH_READAHEAD -o $(BIN_DIR)/read_noos_fullpfetch $(LIBS)
	gcc $^ $(FLAGS) $(ONLYAPP_PREFETCH) -DDONT_READ_FILE -DPREFETCH_READAHEAD -o $(BIN_DIR)/dont_read_noos_pfetch $(LIBS)
	gcc $^ $(FLAGS) -DONLYAPP -DPREAD_RA -o $(BIN_DIR)/preadra_noos_seq $(LIBS)

test: read.c utils/thpool.c
	gcc $^ $(FLAGS) -o $(BIN_DIR)/read_onlyospfetch $(LIBS)
	gcc $^ $(FLAGS) -DONLYAPP -o $(BIN_DIR)/read_nopfetch $(LIBS)
	gcc $^ $(FLAGS) -DNR_RA_PAGES=$(NR_RA_PG) -o $(BIN_DIR)/read_noprefetch $(LIBS)
	gcc $^ $(FLAGS) -DDONT_READ_FILE -DCONCURRENT_PREFETCH -DPREFETCH_PREAD_RA -o $(BIN_DIR)/dont_read_os_smallpfetch_preadra $(LIBS)

write: write.c
	gcc write.c $(FLAGS) -o $(BIN_DIR)/write
