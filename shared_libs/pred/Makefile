CXX=g++
CC=gcc

LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11 
INCLUDE=-I./include

#DEBUGFLAGS=-DDEBUG
NOBGTHREADS=-D__NO_BG_THREADS ##disables worker
DELAYPRFETCH=-D_DELAY_PREFETCH
PINCORES=-DPIN_ALL
CROSSLAYER=-DCROSSLAYER ##Enables file stats in custom linux 5.14
DISABLEPRED=-DCONTROL_PRED ##Disables app prefetching

all: nopred seq onlyapppred

#This allows app predictor but switches off lib predictor
onlyapppred: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libonlyapppred.so $^ $(LIBS) $(DEBUGFLAGS) $(CROSSLAYER)

#This doesnt allow app or lib predictor
nopred: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libnopred.so $^ $(LIBS) $(DEBUGFLAGS) $(CROSSLAYER) $(DISABLEPRED)

#This doesnt limit app predictor and activates lib predictor
seq: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libcrosslayer.so $^ $(LIBS) $(DEBUGFLAGS) -DPREDICTOR -DSEQUENTIAL $(NOBGTHREADS) $(DELAYPRFETCH) $(CROSSLAYER) #$(PINCORES)

clean:
	rm -rf *.o
	rm *.so

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib

uninstall:
	sudo rm /usr/local/lib/libonlyapppred.so
	sudo rm /usr/local/lib/libnopred.so
	sudo rm /usr/local/lib/libcrosslayer.so
	sudo rm /usr/lib/libonlyapppred.so
	sudo rm /usr/lib/libnopred.so
	sudo rm /usr/lib/libcrosslayer.so
