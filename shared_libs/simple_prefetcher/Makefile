CXX=g++
CC=gcc

LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11 -g
INCLUDE=

NR_RA_PG=40


#DEBUG=-DDEBUG
VAR_FLAGS=-DNR_RA_PAGES=$(NR_RA_PG)

DISABLE_FADV_RANDOM=-DDISABLE_FADV_RANDOM ##Disables any FADV_RANDOM from App
CONCURRENT_RA=-DCONCURRENT_PREFETCH -DPREFETCH_READAHEAD
CONCURRENT_FULL_RA=-DCONCURRENT_PREFETCH -DPREFETCH_READAHEAD -DFULL_PREFETCH
SEQ_PREAD_RA=-DSEQ_PREFETCH


all: simpleprefetcher simplefullprefetcher simplenoprefetcher simplepreadra

simplepreadra: frontend.cpp
	$(CXX) $(INCLUDE) $(FLAGS) -o libsimplepreadra.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(SEQ_PREAD_RA)

simpleprefetcher: frontend.cpp
	$(CXX) $(INCLUDE) $(FLAGS) -o libsimpleprefetcher.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(CONCURRENT_RA)

simplefullprefetcher: frontend.cpp
	$(CXX) $(INCLUDE) $(FLAGS) -o libsmpl_fullprefetcher.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) $(CONCURRENT_FULL_RA)

simplenoprefetcher: frontend.cpp
	$(CXX) $(INCLUDE) $(FLAGS) -o libsimplenoprefetcher.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) 

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib
