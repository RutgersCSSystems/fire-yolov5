CXX=g++-4.8
CC=gcc-4.8

LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11 
INCLUDE=-I./include

#DEBUGFLAGS=-DDEBUG
#NOBGTHREADS=-D__NO_BG_THREADS ##disables worker
DELYAPRFETCH=-D_DELAY_PREFETCH
PINCORES=-DPIN_ALL


all: nopred seq 

nopred: frontend.cpp sequential.cpp ngram.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -o libnopred.so $^ $(LIBS)

seq: frontend.cpp sequential.cpp ngram.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libcrosslayer.so $^ $(LIBS) -DPREDICTOR -DSEQUENTIAL $(DEBUGFLAGS) $(NOBGTHREADS) $(DELAYPRFETCH) $(PINCORES)

ngram: frontend.cpp ngram.cpp util.cpp predictor.cpp
	$(CXX) $(FLAGS) -o libcrosslayer.so $^ $(LIBS) -DPREDICTOR -DNGRAM $(DEBUGFLAGS) $(DELAYPRFETCH)

clean:
	rm -rf *.o
	rm *.so

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib

uninstall:
	sudo rm /usr/local/lib/libcfun.so 
	sudo rm /usr/lib/libcfun.so 
