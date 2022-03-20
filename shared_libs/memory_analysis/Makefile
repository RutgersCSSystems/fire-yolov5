CXX=g++
CC=gcc

LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11 -Wno-unused-result
INCLUDE=
#DEBUG=-DDEBUG

KB=1024
MB=`echo "$(KB)*1024" | bc`

SOURCES = preload.cpp

all: $(SOURCES)
	$(CXX) $(INCLUDE) $(FLAGS) -o lib_memusage.so $^ $(LIBS) $(DEBUG)

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib
