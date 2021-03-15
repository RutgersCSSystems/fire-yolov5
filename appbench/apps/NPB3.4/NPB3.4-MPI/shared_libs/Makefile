
CXX=g++
CC=gcc
LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared

all: reclaimer

reclaimer: cfun.cpp pre.c
	$(CXX) $(FLAGS) -o libcfun.so cfun.cpp -DDEBUG $(LIBS)
	$(CC) $(FLAGS) -o pre.so pre.c $(LIBS)

install:
	sudo cp *.so /usr/local/lib
	sudo cp *.so /usr/lib

uninstall:
	sudo rm /usr/local/lib/libcfun.so 
	sudo rm /usr/lib/libcfun.so 
	sudo rm /usr/lib/pre.so 
	sudo rm /usr/local/lib/pre.so 

#all:
#i	gcc -fPIC -shared -o libcfun.so cfun.c
	#sudo mv libcfun.so 
	#gcc -fPIC -shared pre.c -o pre.so -lpthread -ldl
