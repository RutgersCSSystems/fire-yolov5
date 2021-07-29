CXX=g++
CC=gcc

LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11 
INCLUDE=-I./include

#DEBUGFLAGS=-DDEBUG
#NOBGTHREADS=-D__NO_BG_THREADS ##disables worker
DELYAPRFETCH=-D_DELAY_PREFETCH
PINCORES=-DPIN_ALL


all: nopred seq 

nopred: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libnopred.so $^ $(LIBS) $(DEBUGFLAGS)

seq: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libcrosslayer.so $^ $(LIBS) $(DEBUGFLAGS) -DPREDICTOR -DSEQUENTIAL $(NOBGTHREADS) $(DELAYPRFETCH) #$(PINCORES) 

clean:
	rm -rf *.o
	rm *.so

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib

uninstall:
	sudo rm /usr/local/lib/libcfun.so 
	sudo rm /usr/lib/libcfun.so 
