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

#define __NR_start_trace 333
#define __NR_start_crosslayer 448

#define likely(x)      __builtin_expect(!!(x), 1)
#define unlikely(x)    __builtin_expect(!!(x), 0)


#define CLEAR_COUNT     0
#define COLLECT_TRACE 1
#define PRINT_STATS 2
#define PFN_TRACE 4
#define PFN_STAT 5
#define TIME_TRACE 6
#define TIME_STATS 7
#define TIME_RESET 8
#define COLLECT_ALLOCATE 9
#define PRINT_PPROC_PAGESTATS 10

#define ENABLE_FILE_STATS 1
#define DISABLE_FILE_STATS 2
#define RESET_GLOBAL_STATS 3
#define PRINT_GLOBAL_STATS 4
#define CACHE_USAGE_CONS 5
#define CACHE_USAGE_DEST 6
#define CACHE_USAGE_RET 7

#define ENABLE_PVT_LRU 24
#define PRINT_PVT_LRU_STATS 25

static void con() __attribute__((constructor));
static void dest() __attribute__((destructor));

/*Thread local constructor*/
thread_cons_dest::thread_cons_dest(void){
    printf("Thread local constructor \n");
    //thread local constructor
}

thread_cons_dest::~thread_cons_dest(void){
    printf("Thread local destructor \n");
}

/*Constructor*/
void con(){
    printf("Process contructor \n");
}


/*Destructor*/
void dest(){
    printf("Process destructor \n");

}

#ifndef DISABLE_INTERCEPTING

ssize_t readahead(int fd, off_t offset, size_t count){
    ssize_t ret = 0;

perform_ra:
    ret = real_readahead(fd, offset, count);

#ifdef ADVISE_ACCESS_PATTERN
    printf("TID:%ld,FUNC:%s,FD:%d,OFFSET:%ld,SIZE=%ld\n", gettid(), __func__, fd, offset, count);
#endif

done:
    return ret;
}


int posix_fadvise(int fd, off_t offset, off_t len, int advice){
    int ret = 0;

    ret = real_posix_fadvise(fd, offset, len, advice);

#ifdef ADVISE_ACCESS_PATTERN
    printf("TID:%ld,FUNC:%s,FD:%d,OFFSET:%ld,ADVICE:%d\n", gettid(), __func__, fd, offset, advice);
#endif

exit:
    return ret;
}


int open(const char *pathname, int flags, ...){
    //touch_tcd();

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

#ifdef OPEN_ACCESS_PATTERN
    printf("TID:%ld,FUNC:%s,FD:%d\n", gettid(), __func__, fd);
#endif

exit:
    return fd;
}


FILE *fopen(const char *filename, const char *mode){
    int fd;
    //touch_tcd();

    FILE *ret;
    ret = real_fopen(filename, mode);

#ifdef OPEN_ACCESS_PATTERN
    printf("TID:%ld,FUNC:%s,FD:%d\n", gettid(), __func__, fd);
#endif

    return ret;
}


size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream){

    size_t amount_read = 0;

    // Perform the actual system call
    amount_read = real_fread(ptr, size, nmemb, stream);

#ifdef READ_ACCESS_PATTERN
    printf("TID:%ld,FUNC:%s,FD:%d,OFFSET:%ld,SIZE=%ld\n", 
            gettid(), __func__, fileno(stream), ftell(stream), size*nmemb);
#endif

    return amount_read;
}


ssize_t read(int fd, void *data, size_t size){

    ssize_t amount_read = real_read(fd, data, size);

#ifdef READ_ACCESS_PATTERN
    printf("TID:%ld,FUNC:%s,FD:%d,OFFSET:%ld,SIZE=%ld\n", 
            gettid(), __func__, fd, lseek(fd, 0, SEEK_CUR), size);
#endif

    return amount_read;
}


ssize_t pread(int fd, void *data, size_t size, off_t offset){

    //printf("%ld called %s: called for fd:%d\n", gettid(), __func__, fd);
    ssize_t amount_read;
    size_t pfetch_size = 0;

    amount_read = real_pread(fd, data, size, offset);

#ifdef READ_ACCESS_PATTERN
    printf("TID:%ld,FUNC:%s,FD:%d,OFFSET:%ld,SIZE=%ld\n", 
            gettid(), __func__, fd, offset, size);
#endif

    return amount_read;
}


size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){ 

    // Perform the actual system call
    size_t amount_written = real_fwrite(ptr, size, nmemb, stream);

#ifdef WRITE_ACCESS_PATTERN
    printf("TID:%ld,FUNC:%s,FD:%d,OFFSET:%ld,SIZE=%ld\n", 
            gettid(), __func__, fileno(stream), ftell(stream), size*nmemb);
#endif

    return amount_written;
}


ssize_t write(int fd, const void *data, size_t size){

    ssize_t amount_written = real_write(fd, data, size);

#ifdef WRITE_ACCESS_PATTERN
    printf("TID:%ld,FUNC:%s,FD:%d,OFFSET:%ld,SIZE=%ld\n", 
            gettid(), __func__, fd, lseek(fd, 0, SEEK_CUR), size);
#endif

    return amount_written;
}

int fclose(FILE *stream){

#ifdef CLOSE_ACCESS_PATTERN
    printf("TID:%ld,FUNC:%s,FD:%d\n", 
            gettid(), __func__, ftell(stream));
#endif
    return real_fclose(stream);
}


int close(int fd){

#ifdef CLOSE_ACCESS_PATTERN
    printf("TID:%ld,FUNC:%s,FD:%d\n", 
            gettid(), __func__, fd);
#endif
    return real_close(fd);
}


uid_t getuid(){
    return real_getuid();
}

#endif //DISABLE_INTERCEPTING

