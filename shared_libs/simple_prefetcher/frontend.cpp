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

#include "util.hpp"
#include "frontend.hpp"

static void con() __attribute__((constructor));
static void dest() __attribute__((destructor));

void con(){
    printf("CONSTRUCTOR GETTING CALLED \n");
}


void dest(){
    printf("DESTRUCTOR GETTING CALLED \n");
}


/*
 * function run by the prefetcher pthread
 */
void *prefetcher_th(void *arg) {
        long tid = gettid();
        struct thread_args *a = (struct thread_args*)arg;
        debug_printf("TID:%ld: going to fetch from %ld for size %ld on file %d, rasize = %ld\n", 
                        tid, a->offset, a->file_size, a->fd, a->prefetch_size);

        off_t curr_pos = 0;
        size_t readnow;

        while (curr_pos < a->file_size){
#ifdef PREFETCH_READAHEAD
                if(readahead(a->fd, (curr_pos + a->offset), a->prefetch_size) > 0){
                        printf("error while readahead: TID:%ld \n", tid);
                        goto exit;
                }
#endif
                curr_pos += a->prefetch_size;
        }
exit:
        free(arg);
}


void inline spawn_prefetcher(int fd){
#ifndef NO_PREFETCH
    pthread_t thread;
    off_t filesize = reg_fd(fd);

    if(filesize){
        struct thread_args *arg = (struct thread_args *)malloc(sizeof(struct thread_args));
        arg->fd = fd;
        arg->offset = 0;
        arg->file_size = filesize;
        arg->prefetch_size = NR_RA_PAGES * PAGESIZE;
        pthread_create(&thread, NULL, prefetcher_th, (void*)arg);
    }
#endif
}


int open(const char *pathname, int flags, ...){
    int fd;
    if(flags & O_CREAT){
        va_list valist;
        va_start(valist, flags);
        mode_t mode = va_arg(valist, mode_t);
        va_end(valist);
        fd = real_open(pathname, flags, mode);
    }
    else{
        fd = real_open(pathname, flags, 0);
    }

    if(fd < 0)
        goto exit;

    debug_printf("Opening file %s\n", pathname);

    spawn_prefetcher(fd);

exit:
    return fd;
}


FILE *fopen(const char *filename, const char *mode){
    int fd;

    FILE *ret;
    ret = real_fopen(filename, mode);
    if(!ret)
        return ret;

    debug_printf("FOpening file\n");

    fd = fileno(ret);
    spawn_prefetcher(fd);

    return ret;
}

