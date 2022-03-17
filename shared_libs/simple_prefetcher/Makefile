CXX=g++
CC=gcc

LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11 -Wno-unused-result
INCLUDE=

KB=1024
MB=`echo "$(KB)*1024" | bc`

NR_RA_PAGES=40
NR_WORKERS=2
PORTION_PAGES=32
NR_ADJACENT_CHECK=1
MIN_FILE_SZ=$(MB)

SOURCES = frontend.cpp utils/thpool.c utils/bitarray.c

#DEBUG=-DDEBUG
VAR_FLAGS=-DNR_RA_PAGES=$(NR_RA_PAGES) -DNR_WORKERS=$(NR_WORKERS) -DPORTION_PAGES=$(PORTION_PAGES)
VAR_FLAGS+=-DNR_ADJACENT_CHECK=$(NR_ADJACENT_CHECK) -DMIN_FILE_SZ=$(MIN_FILE_SZ)

CONCURRENT_RA=-DCONCURRENT_PREFETCH -DPREFETCH_READAHEAD
CONCURRENT_FILE_RA=-DCONCURRENT_PREFETCH -DPREFETCH_READAHEAD -DFULL_PREFETCH
SEQ_PREAD_RA=-DSEQ_PREFETCH
SEQ_FULL_PREAD_RA=-DSEQ_PREFETCH -DFULL_PREFETCH ##Not implmented yet

#Real Deal
DISABLE_FADV_RANDOM=-DDISABLE_FADV_RANDOM ##Disables any FADV_RANDOM from App
THPOOL_FILE_RA=-DTHPOOL_PREFETCH -DPREFETCH_READAHEAD -DFULL_PREFETCH -DBLIND_PREFETCH
PREDICTOR_THPOOL_FILE_RA=-DTHPOOL_PREFETCH -DPREFETCH_READAHEAD -DFULL_PREFETCH -DPREDICTOR
PREDICTOR_THPOOL_BLOCK_RA=-DTHPOOL_PREFETCH -DPREFETCH_READAHEAD -DPREDICTOR


#all: simpleprefetcher simplefullprefetcher simplenoprefetcher simplepreadra
#all: Vanilla Cross_FileRA_NoPred_MaxMem_BG
all: Vanilla OSonly Cross_FileRA_NoPred_MaxMem_BG Cross_FileRA_Pred_MaxMem_BG Cross_BlockRA_Pred_MaxMem_BG

#simplepreadra: frontend.cpp
#	$(CXX) $(INCLUDE) $(FLAGS) -o libsimplepreadra.so $^ $(LIBS) $(DEBUG) \
#	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(SEQ_PREAD_RA)

#simpleprefetcher: frontend.cpp
#	$(CXX) $(INCLUDE) $(FLAGS) -o libsimpleprefetcher.so $^ $(LIBS) $(DEBUG) \
#	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(CONCURRENT_RA)

#simplefullprefetcher: frontend.cpp worker.cpp utils/thpool.c
#	$(CXX) $(INCLUDE) $(FLAGS) -o libsmpl_fullprefetcher.so $^ $(LIBS) $(DEBUG) \
	#$(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(CONCURRENT_FILE_RA)

Cross_FileRA_Pred_MaxMem_BG: $(SOURCES)
	$(CXX) $(INCLUDE) $(FLAGS) -o lib_CFPMB.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(PREDICTOR_THPOOL_FILE_RA)

Cross_BlockRA_Pred_MaxMem_BG: $(SOURCES)
	$(CXX) $(INCLUDE) $(FLAGS) -o lib_CBPMB.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(PREDICTOR_THPOOL_BLOCK_RA)

Cross_FileRA_NoPred_MaxMem_BG: $(SOURCES)
	$(CXX) $(INCLUDE) $(FLAGS) -o lib_CFNMB.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(THPOOL_FILE_RA)

OSonly: $(SOURCES)
	$(CXX) $(INCLUDE) $(FLAGS) -o lib_OSonly.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) 

Vanilla: $(SOURCES)
	$(CXX) $(INCLUDE) $(FLAGS) -o lib_Vanilla.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS)

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib
