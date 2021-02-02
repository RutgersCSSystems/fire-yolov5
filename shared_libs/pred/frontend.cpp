#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <dlfcn.h>
#include <unistd.h>
#include <fcntl.h>
#include <limits.h>
#include <sched.h>
#include <errno.h>

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
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>


#include "frontend.hpp"
#include "predictor.hpp"
#include "worker.hpp"

#define __NR_start_trace 333

#define CLEAR_COUNT     0
#define COLLECT_TRACE 1
#define PRINT_STATS 2
#define PFN_TRACE 4
#define PFN_STAT 5
#define TIME_TRACE 6
#define TIME_STATS 7
#define TIME_RESET 8
#define COLLECT_ALLOCATE 9
#define PRINT_ALLOCATE 10

#define ENABLE_PVT_LRU 24
#define PRINT_PVT_LRU_STATS 25

static void con() __attribute__((constructor));
static void dest() __attribute__((destructor));


void set_pvt_lru(){
    syscall(__NR_start_trace, ENABLE_PVT_LRU, 0);
}


void con(){
    //struct sigaction action;

    fprintf(stderr, "init tracing...\n");

    set_pvt_lru();
    thread_fn(); //spawn worker thread

}


void dest(){
    fprintf(stderr, "application termination...\n");
    //syscall(__NR_start_trace, PRINT_STATS);

    //syscall(__NR_start_trace, PRINT_ALLOCATE, 0);

    /*
       a = syscall(__NR_start_trace, CLEAR_COUNT);
       a = syscall(__NR_start_trace, PFN_STAT);
       a = syscall(__NR_start_trace, TIME_STATS);
       a = syscall(__NR_start_trace, TIME_RESET);
       */

    //syscall(__NR_start_trace, CLEAR_COUNT, 0);


    /*
     * This code snippet prints the Rusage parameters
     * at destruction
     */
    struct rusage Hello;
    if (getrusage(RUSAGE_SELF, &Hello) != 0)
    {
        fprintf(stderr, "Unable to get rusage\n");
    }

    printf("MaxRSS= %lu KB, "
            "SharedMem= %lu KB, "
            "HardPageFault= %lu\n"
            , Hello.ru_maxrss, Hello.ru_ixrss, Hello.ru_majflt);

    syscall(__NR_start_trace, PRINT_PVT_LRU_STATS, 0);

}


size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream){
#ifdef DEBUG
    std::cout << "fread" << std::endl;
#endif
    size_t amount_read;

    // Perform the actual system call
    amount_read = real_fread(ptr, size, nmemb, stream);

#ifdef PREDICTOR
    int fd; 

    if(fd = reg_file(stream)){ //this is a regular file
        ////lseek doesnt work with f* commands
        handle_read(fd, ftell(stream), size*nmemb);
    }
#endif

    return amount_read;
}


ssize_t read(int fd, void *data, size_t size){
#ifdef DEBUG
    printf("Hello read\n");
#endif
    ssize_t amount_read = real_read(fd, data, size);

#ifdef PREDICTOR
    if(reg_fd(fd)){
#ifdef DEBUG
        printf("fd: %d lseek: %ld bytes: %lu\n", fd, lseek(fd, 0, SEEK_CUR), size );
#endif
        handle_read(fd, lseek(fd, 0, SEEK_CUR), size);
    }
#endif

    return amount_read;
}


size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){
    // Perform the actual system call
    size_t amount_written = real_fwrite(ptr, size, nmemb, stream);

    return amount_written;
}


ssize_t write(int fd, const void *data, size_t size){
    ssize_t amount_written = real_write(fd, data, size);
    return amount_written;
}


int fclose(FILE *stream){
#ifdef DEBUG
    printf("fclose detected\n");
#endif

#ifdef PREDICTOR
    int fd;
    if(fd = reg_file(stream)){
        handle_close(fd);
    }
#endif
    return real_fclose(stream);
}


int close(int fd){
#ifdef DEBUG
    printf("File close detected\n");
#endif

#ifdef PREDICTOR
    if(reg_fd(fd)){
        //remove from the predictor data
        handle_close(fd);
    }
#endif

    return real_close(fd);
}

//returns fd if  FILE is a regular file
int reg_file(FILE *stream){
    return reg_fd(fileno(stream));
}

//returns true if fd is regular file
bool reg_fd(int fd)
{
    if(!fd)
        return false;

    struct stat st;

    if(fstat(fd, &st) == 0){
        if(S_ISREG(st.st_mode)){
            return true;
        }
    }
    return false;
}
