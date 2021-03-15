CXX=g++
CC=gcc
LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11 

#DEBUGFLAGS=-DDEBUG
#NOBGTHREADS=-D__NO_BG_THREADS ##disables worker

all: nopred seq 

nopred: frontend.cpp sequential.cpp ngram.cpp util.cpp predictor.cpp worker.cpp
	$(CXX) $(FLAGS) -o libnopred.so $^ $(LIBS) 

seq: frontend.cpp sequential.cpp ngram.cpp util.cpp predictor.cpp worker.cpp
	$(CXX) $(FLAGS) -g -o libcrosslayer.so $^ $(LIBS) -DPREDICTOR -DSEQUENTIAL $(DEBUGFLAGS) $(NOBGTHREADS)

ngram: frontend.cpp ngram.cpp util.cpp predictor.cpp
	$(CXX) $(FLAGS) -o libcrosslayer.so $^ $(LIBS) -DPREDICTOR -DNGRAM $(DEBUGFLAGS)

clean:
	rm -rf *.o
	rm *.so

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib

uninstall:
	sudo rm /usr/local/lib/libcfun.so 
	sudo rm /usr/lib/libcfun.so 
