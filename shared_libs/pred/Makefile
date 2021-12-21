CXX=g++
CC=gcc

LIBS=-lpthread -lrt -ldl
FLAGS=-fPIC -shared -std=gnu++11
INCLUDE=-I./include

#DEBUGFLAGS=-DDEBUG
NOBGTHREADS=-D__NO_BG_THREADS ##disables worker
DELAYPRFETCH=-D_DELAY_PREFETCH

#PINCORES=-DPIN_ALL
CROSSLAYER=-DCROSSLAYER ##Enables file stats in custom linux 5.14
DISABLEAPPPRED=-DCONTROL_PRED ##Disables app prefetching
DISABLEOSPRED=-DDISABLE_OS_PREFETCH ##Disables OS prefetching
DISABLE_FADV_RANDOM=-DDISABLE_FADV_RANDOM ##Disables any FADV_RANDOM from App
ENABLE_WILLNEED_OPEN=-DENABLE_WILLNEED_OPEN ##Enables FADV_WILLNEED when a file is opened
#ENABLE_SHARED_MEM=-DMMAP_SHARED_DAT ##Enables sending only unique readaheads
ENABLE_GLOBAL_STATS=-DENABLE_GLOBAL_CACHE_STATS ##Enables global stats for cache hits/misses etc in custom linux 5.14
READ_RA=-DREAD_RA ##Enables read_ra syscall instead of read and readahead for all the read calls intercepted
DISABLE_INTERCEPTING=-DDISABLE_INTERCEPTING ##Disables any form of intercepting from the library
FETCH_WHOLE_FILE=-DFETCH_WHOLE_FILE ##Fetches whole file when it is opened (modified linux only)
CACHE_LIMITING=-DENABLE_CACHE_LIMITING ##Enable Cache accounting and limiting (modified linux only)

all: nopred seq onlyapppred os_apppred onlyospred onlylibpred os_libpred juststats onlyintercept cache_lim_os_libpred


#This allows lib predictor but switches off app and OS predictor (Disable any FADV_RANDOM)
onlylibpred: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libonlylibpred.so $^ $(LIBS) $(DEBUGFLAGS) \
	    -DPREDICTOR -DSEQUENTIAL $(NOBGTHREADS) $(DELAYPRFETCH) $(CROSSLAYER) \
	    $(DISABLEOSPRED) $(DISABLEAPPPRED) $(ENABLE_WILLNEED_OPEN) $(READ_RA)

#This allows app predictor but switches off lib and OS predictor (Disable any FADV_RANDOM)
onlyapppred: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libonlyapppred.so $^ $(LIBS) $(DEBUGFLAGS) \
	    $(CROSSLAYER) $(DISABLEOSPRED) $(DISABLE_FADV_RANDOM) $(ENABLE_WILLNEED_OPEN) \
	    $(ENABLE_SHARED_MEM)

os_libpred: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libos_libpred.so $^ $(LIBS) $(DEBUGFLAGS) \
	    -DPREDICTOR -DSEQUENTIAL $(NOBGTHREADS) $(DELAYPRFETCH) $(CROSSLAYER) \
	    $(DISABLEAPPPRED) $(DISABLE_FADV_RANDOM) $(READ_RA)

#This allows app predictor but switches off lib and OS predictor
os_apppred: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libos_apppred.so $^ $(LIBS) $(DEBUGFLAGS) \
	    $(DISABLE_FADV_RANDOM) $(ENABLE_SHARED_MEM) $(ENABLE_GLOBAL_STATS)

#This doesnt allow app or lib predictor, but OS prefetchers are working 
onlyospred: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libonlyospred.so $^ $(LIBS) $(DEBUGFLAGS) \
	    $(DISABLEAPPPRED) $(DISABLE_FADV_RANDOM)

#Cache limited library prefetching
cache_lim_os_libpred: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libcache_lim_os_libpred.so $^ $(LIBS) $(DEBUGFLAGS) \
	    -DPREDICTOR -DSEQUENTIAL $(NOBGTHREADS) $(DELAYPRFETCH) $(CROSSLAYER) \
	    $(DISABLEAPPPRED) $(DISABLE_FADV_RANDOM) $(READ_RA) $(FETCH_WHOLE_FILE) \
	    $(CACHE_LIMITING)

#This doesnt allow App or lib or OS predictor 
nopred: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libnopred.so $^ $(LIBS) $(DEBUGFLAGS) \
	    $(CROSSLAYER) $(DISABLEAPPPRED) $(DISABLEOSPRED) $(ENABLE_SHARED_MEM)

#This doesnt limit app predictor and activates lib predictor
seq: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libcrosslayer.so $^ $(LIBS) $(DEBUGFLAGS) \
	-DPREDICTOR -DSEQUENTIAL $(NOBGTHREADS) $(DELAYPRFETCH) $(CROSSLAYER) \
	$(READ_RA) #$(PINCORES) 

juststats: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libjuststats.so $^ $(LIBS) $(DEBUGFLAGS) \
	    $(DISABLE_INTERCEPTING) $(ENABLE_GLOBAL_STATS) $(CACHE_LIMITING)

onlyintercept: frontend.cpp sequential.cpp util.cpp predictor.cpp worker.cpp utils/thpool.c
	$(CXX) $(INCLUDE) $(FLAGS) -g -o libonlyintercept.so $^ $(LIBS) \
	    $(DISABLE_FADV_RANDOM) $(CACHE_LIMITING) $(FETCH_WHOLE_FILE)


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
