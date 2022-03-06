CXX=g++
CC=gcc

LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11 -g
INCLUDE=

NR_RA_PG=20


VAR_FLAGS=-DNR_RA_PAGES=$(NR_RA_PG)


all: frontend.cpp
	$(CXX) $(INCLUDE) $(FLAGS) $(VAR_FLAGS) -DPREFETCH_READAHEAD -o libsimpleprefetcher.so $^ $(LIBS)
	$(CXX) $(INCLUDE) $(FLAGS) -DPREFETCH_READAHEAD -DNO_PREFETCH -o libsimplenoprefetcher.so $^ $(LIBS)

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib
