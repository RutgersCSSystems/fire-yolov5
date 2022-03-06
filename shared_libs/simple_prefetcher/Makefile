CXX=g++
CC=gcc

LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11
INCLUDE=


all: frontend.cpp
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libsimpleprefetcher.so $^ $(LIBS)
