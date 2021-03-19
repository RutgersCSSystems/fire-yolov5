CXX=g++
CC=gcc
LIBS=-lpthread -lrt -ldl -lnuma
#FLAGS=-fPIC -shared -std=gnu++11 
FLAGS=-std=c++0x -fno-builtin-memcmp -fpermissive -pthread -DOS_LINUX -DLEVELDB_PLATFORM_POSIX -DMULTILEVEL_IMMUTABLE -DUSE_OFFSETS -DENABLE_RECOVERY -D_ENABLE_PREDICTION -O3 -march=native -DNDEBUG -std=gnu++0x -fPIC

all: cpumap.cc thpool.cc test.c
	$(CXX) $(FLAGS) -o test $^ $(LIBS)
