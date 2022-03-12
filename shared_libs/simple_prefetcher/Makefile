CXX=g++
CC=gcc

LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11 -g
INCLUDE=

NR_RA_PG=40
NR_WORKERS=2

#DEBUG=-DDEBUG
VAR_FLAGS=-DNR_RA_PAGES=$(NR_RA_PG) -DNR_WORKERS=$(NR_WORKERS)

CONCURRENT_RA=-DCONCURRENT_PREFETCH -DPREFETCH_READAHEAD
CONCURRENT_FILE_RA=-DCONCURRENT_PREFETCH -DPREFETCH_READAHEAD -DFULL_PREFETCH
SEQ_PREAD_RA=-DSEQ_PREFETCH
SEQ_FULL_PREAD_RA=-DSEQ_PREFETCH -DFULL_PREFETCH ##Not implmented yet

#Real Deal
DISABLE_FADV_RANDOM=-DDISABLE_FADV_RANDOM ##Disables any FADV_RANDOM from App
THPOOL_FILE_RA=-DTHPOOL_PREFETCH -DPREFETCH_READAHEAD -DFULL_PREFETCH


#all: simpleprefetcher simplefullprefetcher simplenoprefetcher simplepreadra
#all: Vanilla Cross_FileRA_NoPred_MaxMem_BG
all: Vanilla OSonly Cross_FileRA_NoPred_MaxMem_BG

simplepreadra: frontend.cpp
	$(CXX) $(INCLUDE) $(FLAGS) -o libsimplepreadra.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(SEQ_PREAD_RA)

simpleprefetcher: frontend.cpp
	$(CXX) $(INCLUDE) $(FLAGS) -o libsimpleprefetcher.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(CONCURRENT_RA)

simplefullprefetcher: frontend.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -o libsmpl_fullprefetcher.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(CONCURRENT_FILE_RA)

Cross_FileRA_NoPred_MaxMem_BG: frontend.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -o lib_CFNMB.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(THPOOL_FILE_RA)
	    #$(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(THPOOL_FILE_RA)

OSonly: frontend.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -o lib_OSonly.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) 

Vanilla: frontend.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -o lib_Vanilla.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS)

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib
