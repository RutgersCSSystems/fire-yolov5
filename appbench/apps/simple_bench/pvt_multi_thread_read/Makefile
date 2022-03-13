CC=gcc
CXX=g++
LIBS=-lrt -lpthread -lm
SIZE=10 ##Test file size in GBs
NR_READ_PAGES=40 ##Nr of pages to req in one read syscall
NR_THREADS=4 ## Nr of readers 
BIN_DIR=./bin


DEBUG=-DDEBUG
FLAGS=-DFILESZ=$(SIZE) -DNR_PAGES_READ=$(NR_READ_PAGES) -DNR_THREADS=$(NR_THREADS)

all: read write

read: read.cpp utils/thpool.c
	$(CXX) $^ $(FLAGS) $(DEBUG) -o $(BIN_DIR)/read $(LIBS)

write: write.cpp utils/thpool.c
	$(CXX) $^ $(FLAGS) $(DEBUG) -o $(BIN_DIR)/write $(LIBS)

clean:
	rm bigfakefile*
	rm $(BIN_DIR)/*
