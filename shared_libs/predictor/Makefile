
CXX=g++
CC=gcc
LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared

all: reclaimer

reclaimer: predictor.cpp
	$(CXX) $(FLAGS) -o libpredictor.so predictor.cpp $(LIBS) -DPREDICT

debug: predictor.cpp
	$(CXX) $(FLAGS) -o libpredictor.so predictor.cpp $(LIBS) -DDEBUG -DPREDICT

pattern: predictor.cpp
	$(CXX) $(FLAGS) -o libpredictor.so predictor.cpp $(LIBS) -DPATTERN

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib

uninstall:
	sudo rm /usr/local/lib/libcfun.so 
	sudo rm /usr/lib/libcfun.so 

