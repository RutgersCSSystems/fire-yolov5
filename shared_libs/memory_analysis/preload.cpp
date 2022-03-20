#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <dlfcn.h>
#include <unistd.h>
#include <fcntl.h>
#include <limits.h>
#include <sched.h>
#include <stdarg.h>
#include <errno.h>
#include <time.h>

#include <iostream>
#include <cstdlib>
#include <ctime>
#include <fstream>
#include <algorithm>
#include <map>
#include <deque>
#include <unordered_map>
#include <string>
#include <iterator>

#include <sys/sysinfo.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <sys/resource.h>

#include "preload.hpp"

#define likely(x)      __builtin_expect(!!(x), 1)
#define unlikely(x)    __builtin_expect(!!(x), 0)

static void con() __attribute__((constructor));
static void dest() __attribute__((destructor));

struct shared_dat *shared_data; //all shared data across procs/threads

pthread_t thread_id;

long initial_memfree;
long initial_cached;
long memfree;
long cached;

typedef struct MEMPACKED
{
        char name1[20];
        unsigned long MemTotal;
        char name2[20];
        unsigned long MemFree;
        char name3[20];
        unsigned long Buffers;
        char name4[20];
        unsigned long Cached;
        char name5[20];
        unsigned long MemAvailable;

}MEM_OCCUPY;

int  get_meminfo(MEM_OCCUPY * lpMemory)
{
        FILE *fd;
        char buff[128];
        fd = fopen("/proc/meminfo", "r");
        if(fd <0) return -1;
        fgets(buff, sizeof(buff), fd);
        sscanf(buff, "%s %lu ", lpMemory->name1, &lpMemory->MemTotal);
        fgets(buff, sizeof(buff), fd);
        sscanf(buff, "%s %lu ", lpMemory->name2, &lpMemory->MemFree);
        fgets(buff, sizeof(buff), fd);
        sscanf(buff, "%s %lu ", lpMemory->name5, &lpMemory->MemAvailable);
        fgets(buff, sizeof(buff), fd);
        sscanf(buff, "%s %lu ", lpMemory->name3, &lpMemory->Buffers);
        fgets(buff, sizeof(buff), fd);
        sscanf(buff, "%s %lu ", lpMemory->name4, &lpMemory->Cached);

        fclose(fd);
}


void *memory_analysis(void * arg){

        MEM_OCCUPY mem;

        bool first = true; 

        while(true){
                get_meminfo(&mem);

                //printf("memfree=%ld, cached=%ld\n", memfree, cached);

                if(first){
                        initial_memfree = mem.MemFree;
                        memfree = initial_memfree;

                        initial_cached = mem.Cached;
                        cached = initial_cached;

                        first = false;
                }
                else{
                        memfree = MIN(memfree, mem.MemFree);
                        cached = MAX(cached, mem.Cached);
                }
        }
}



void con(){
        printf("CALLING CONSTRUCTOR\n");

        //Spawn a thread and work
        pthread_create(&thread_id, NULL, memory_analysis, NULL);

}

void dest(){
        printf("application termination...\n");

        pthread_cancel(thread_id);


        long total_mem_used = initial_memfree - memfree;
        long total_cache_used = cached - initial_cached;

        printf("total_anon_used=%ld MB, total_cache=%ld MB\n", (total_mem_used-total_cache_used)/1024, total_cache_used/1024);
}
