CXX=g++
CC=gcc

LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11 -g
INCLUDE=

NR_RA_PG=20


#DEBUG=-DDEBUG
VAR_FLAGS=-DNR_RA_PAGES=$(NR_RA_PG)

DISABLE_FADV_RANDOM=-DDISABLE_FADV_RANDOM ##Disables any FADV_RANDOM from App


all: simpleprefetcher simplefullprefetcher simplenoprefetcher


simpleprefetcher: frontend.cpp
	$(CXX) $(INCLUDE) $(FLAGS) -o libsimpleprefetcher.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) -DPREFETCH_READAHEAD 

simplefullprefetcher: frontend.cpp
	$(CXX) $(INCLUDE) $(FLAGS) -o libsmpl_fullprefetcher.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) -DPREFETCH_READAHEAD -DFULL_PREFETCH

simplenoprefetcher: frontend.cpp
	$(CXX) $(INCLUDE) $(FLAGS) -o libsimplenoprefetcher.so $^ $(LIBS) $(DEBUG) \
	    $(VAR_FLAGS) $(DISABLE_FADV_RANDOM) -DNO_PREFETCH

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib
