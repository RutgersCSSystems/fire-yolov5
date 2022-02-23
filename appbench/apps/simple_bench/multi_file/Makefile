CC=gcc
CXX=g++
LIBS=-lrt -lpthread -lm
SIZE=10 ##Test file size in GBs
NR_RA_PG=40 ##Nr of pages to prefetch in one req
NR_BG_THREADS=4
BIN_DIR=./bin

FLAGS=-DFILESZ=$(SIZE) -DNR_RA_PAGES=$(NR_RA_PG) -DNR_BG_THREADS=$(NR_BG_THREADS)

all: read write

read: read.cpp utils/thpool.c
	$(CXX) $^ $(FLAGS) -o $(BIN_DIR)/read_onlyospfetch $(LIBS)
	$(CXX) $^ $(FLAGS) -DONLYAPP -DNR_RA_PAGES=$(NR_RA_PG) -o $(BIN_DIR)/read_noprefetch $(LIBS)
	$(CXX) $^ $(FLAGS) -DONLYAPP -DPREFETCH -o $(BIN_DIR)/read_onlypfetch $(LIBS)
	$(CXX) $^ $(FLAGS) -DPREFETCH -o $(BIN_DIR)/read_os_smallpfetch $(LIBS)
	$(CXX) $^ $(FLAGS) -DPREFETCH -DFULL_RA -o $(BIN_DIR)/read_os_fullpfetch $(LIBS)
	$(CXX) $^ $(FLAGS) -DPREFETCH -DDONT_READ_FILE -o $(BIN_DIR)/dont_read_os_pfetch $(LIBS)

write: write.cpp utils/thpool.c
	$(CXX) $^ $(FLAGS) -o $(BIN_DIR)/write $(LIBS)

clean:
	rm bigfakefile*
	rm $(BIN_DIR)/*
