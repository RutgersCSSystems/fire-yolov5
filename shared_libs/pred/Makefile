CXX=g++
CC=gcc
LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared

#all: reclaimer

pred: frontend.cpp
	$(CXX) $(FLAGS) -o libpred.so $^ $(LIBS)

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
