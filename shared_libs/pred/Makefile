CXX=g++
CC=gcc
LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared

#all: reclaimer

seq: frontend.cpp sequential.cpp ngram.cpp util.cpp predictor.cpp worker.cpp
	$(CXX) $(FLAGS) -o libcrosslayer.so $^ $(LIBS) -DPREDICTOR -DDEBUG -DSEQUENTIAL

ngram: frontend.cpp ngram.cpp util.cpp predictor.cpp
	$(CXX) $(FLAGS) -o libcrosslayer.so $^ $(LIBS) -DPREDICTOR -DDEBUG -DNGRAM

test: tester.cpp ngram.cpp util.cpp
	$(CXX) -o $@ $^ 

reclaimer: predictor.cpp ngram.cpp
	$(CXX) $(FLAGS) -o libpredictor.so predictor.cpp ngram.cpp util.cpp $(LIBS) -DPREDICTOR

debug: predictor.cpp ngram.cpp
	$(CXX) $(FLAGS) -o libpredictor.so predictor.cpp ngram.cpp $(LIBS) -DDEBUG -DPREDICTOR

pattern: predictor.cpp ngram.cpp
	$(CXX) $(FLAGS) -o libpredictor.so predictor.cpp ngram.cpp $(LIBS) -DPATTERN

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib

uninstall:
	sudo rm /usr/local/lib/libcfun.so 
	sudo rm /usr/lib/libcfun.so 
