CXX=g++
CC=gcc

LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11
INCLUDE=-I./include

#DEBUGFLAGS=-DDEBUG
ACCESS_PATTERN=-DOPEN_ACCESS_PATTERN -DREAD_ACCESS_PATTERN -DWRITE_ACESS_PATTERN -DCLOSE_ACCESS_PATTERN

all: access_pattern

access_pattern: frontend.cpp
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libaccess_pattern.so $^ $(LIBS) $(ACESS_PATTERN)


clean:
	rm -rf *.o
	rm *.so

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib

uninstall:
	sudo rm /usr/local/lib/libaccess_pattern.so
