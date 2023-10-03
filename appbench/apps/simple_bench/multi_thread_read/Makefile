CC=gcc
CXX=g++
LIBS=-lrt -lpthread -lm
SIZE=10 ##Test file size in GBs
NR_READ_PAGES=40 ##Nr of pages to req in one read syscall
NR_THREADS=4 ## Nr of readers 
NR_STRIDE=64
NR_RA_PAGES=256 #nr of pages
BIN_DIR=./bin

COMPOPT=-O3


#DEBUG=-DDEBUG
FLAGS=-DFILESZ=$(SIZE) -DNR_PAGES_READ=$(NR_READ_PAGES) -DNR_THREADS=$(NR_THREADS) -DNR_STRIDE=$(NR_STRIDE) -DNR_RA_PAGES=$(NR_RA_PAGES) $(DEBUG) $(COMPOPT)

SHARED_FLAGS=-DFILESZ=$(SIZE) -DNR_PAGES_READ=$(NR_READ_PAGES) 

all: read_pvt write_pvt write_shared read_shared read_shared_simple read_mmap_shared

read_pvt: read.cpp utils/thpool.c
	$(CXX) $^ $(FLAGS) $(DEBUG) -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_pvt_seq $(LIBS)
	$(CXX) $^ $(FLAGS) $(DEBUG) -DREAD_SEQUENTIAL -DGLOBAL_TIMER -o $(BIN_DIR)/read_pvt_seq_global $(LIBS)
	$(CXX) $^ $(FLAGS) $(DEBUG) -DREAD_SEQUENTIAL -DENABLE_MINCORE_RA -o $(BIN_DIR)/read_pvt_seq_mincore $(LIBS)
	$(CXX) $^ $(FLAGS) $(DEBUG) -DAPP_SINGLE_PREFETCH -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_pvt_seq_vanilla $(LIBS)
	$(CXX) $^ $(FLAGS) $(DEBUG) -DAPP_OPT_PREFETCH -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_pvt_seq_vanilla_opt $(LIBS)
	$(CXX) $^ $(FLAGS) $(DEBUG) -DREAD_SEQUENTIAL -DSTRIDED_READ -o $(BIN_DIR)/read_pvt_strided $(LIBS)
	$(CXX) $^ $(FLAGS) $(DEBUG) -DREAD_RANDOM -o $(BIN_DIR)/read_pvt_rand $(LIBS)



write_pvt: write.cpp utils/thpool.c
	$(CXX) $^ $(FLAGS) $(DEBUG) -o $(BIN_DIR)/write_pvt $(LIBS)

read_shared: read.cpp utils/thpool.c
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_shared_seq $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DREAD_SEQUENTIAL -DGLOBAL_TIMER -o $(BIN_DIR)/read_shared_seq_global $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DREAD_SEQUENTIAL -DENABLE_MINCORE_RA -o $(BIN_DIR)/read_shared_seq_mincore $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DREAD_SEQUENTIAL -DSTATS_PC_MISSES_MINCORE -o $(BIN_DIR)/read_shared_seq_misses $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DAPP_SINGLE_PREFETCH -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_shared_seq_vanilla $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DAPP_SINGLE_PREFETCH -DMODIFIED_RA -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_shared_seq_vanilla_mra $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DAPP_OPT_PREFETCH -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_shared_seq_vanilla_opt $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DREAD_SEQUENTIAL -DSTRIDED_READ -o $(BIN_DIR)/read_shared_strided $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DREAD_RANDOM -o $(BIN_DIR)/read_shared_rand $(LIBS)


read_mmap_shared: read-mmap.cpp utils/thpool.c
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_shared_mmap_seq $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DREAD_RANDOM -o $(BIN_DIR)/read_shared_mmap_rand $(LIBS)
	#$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DAPP_SINGLE_PREFETCH -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_shared_mmap_seq_vanilla $(LIBS)
	#$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DAPP_SINGLE_PREFETCH -DMODIFIED_RA -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_shared_mmap_seq_vanilla_mra $(LIBS)
	#$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DAPP_OPT_PREFETCH -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_shared_mmap_seq_vanilla_opt $(LIBS)




read_shared_simple: read-simple.cpp utils/thpool.c
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_shared_seq_simple $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DREAD_SEQUENTIAL -DGLOBAL_TIMER -o $(BIN_DIR)/read_shared_seq_global_simple $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DAPP_SINGLE_PREFETCH -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_shared_seq_vanilla_simple $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DAPP_SINGLE_PREFETCH -DMODIFIED_RA -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_shared_seq_vanilla_mra_simple $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DAPP_OPT_PREFETCH -DREAD_SEQUENTIAL -o $(BIN_DIR)/read_shared_seq_vanilla_opt_simple $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DREAD_SEQUENTIAL -DSTRIDED_READ -o $(BIN_DIR)/read_shared_strided_simple $(LIBS)
	$(CXX) $^ $(FLAGS) -DSHARED_FILE $(DEBUG) -DREAD_RANDOM -o $(BIN_DIR)/read_shared_rand_simple $(LIBS)

write_shared: write.cpp utils/thpool.c
	$(CXX) $^ $(SHARED_FLAGS) -DNR_THREADS=1 $(DEBUG) -o $(BIN_DIR)/write_shared $(LIBS)

clean:
	rm bigfakefile*
	rm $(BIN_DIR)/*
