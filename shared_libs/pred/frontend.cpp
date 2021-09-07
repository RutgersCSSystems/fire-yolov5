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
#include "util.hpp"

#define __NR_start_trace 333
#define __NR_start_crosslayer 448

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

#define ENABLE_PVT_LRU 24
#define PRINT_PVT_LRU_STATS 25


static void con() __attribute__((constructor));
static void dest() __attribute__((destructor));

real_fopen_t fopen_ptr = NULL;

real_pread_t pread_ptr = NULL;
real_read_t read_ptr = NULL;

real_write_t write_ptr = NULL;

real_fread_t fread_ptr = NULL;
real_fwrite_t fwrite_ptr = NULL;

FILE *real_fopen(const char *filename, const char *mode){

	if(!fopen_ptr)
		fopen_ptr = (real_fopen_t)dlsym(RTLD_NEXT, "fopen");

        return ((real_fopen_t)fopen_ptr)(filename, mode);
}

size_t real_fread(void *ptr, size_t size, size_t nmemb, FILE *stream){

	if(!fread_ptr)
		fread_ptr = (real_fread_t)dlsym(RTLD_NEXT, "fread");

        return ((real_fread_t)fread_ptr)(ptr, size, nmemb, stream);
}

size_t real_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){

	if(!fwrite_ptr)
        	fwrite_ptr = (real_fwrite_t)dlsym(RTLD_NEXT, "fwrite");

        return ((real_fwrite_t)fwrite_ptr)(ptr, size, nmemb, stream);
}

ssize_t real_pread(int fd, void *data, size_t size, off_t offset){

	if(!pread_ptr)
		pread_ptr = (real_pread_t)dlsym(RTLD_NEXT, "pread");

        return ((real_pread_t)pread_ptr)(fd, data, size, offset);
}

ssize_t real_write(int fd, const void *data, size_t size) {

	if(!write_ptr)
		write_ptr = ((real_write_t)dlsym(RTLD_NEXT, "write"));

        return ((real_write_t)write_ptr)(fd, data, size);
}

ssize_t real_read(int fd, void *data, size_t size) {

	if(!read_ptr)
		read_ptr = (real_read_t)dlsym(RTLD_NEXT, "read");

        return ((real_read_t)read_ptr)(fd, data, size);
}


int real_open(const char *pathname, int flags){
        return ((real_open_t)dlsym(RTLD_NEXT, "open"))
            (pathname, flags);
}


void set_crosslayer(){
    syscall(__NR_start_crosslayer, ENABLE_FILE_STATS, 0);
}

void unset_crosslayer(){
    syscall(__NR_start_crosslayer, DISABLE_FILE_STATS, 0);
}

void set_pvt_lru(){
    syscall(__NR_start_trace, ENABLE_PVT_LRU, 0);
}



void con(){
#ifdef CROSSLAYER
	set_crosslayer();
#endif

#if defined PREDICTOR && !defined __NO_BG_THREADS
    debug_print("init tracing...\n");

    //set_pvt_lru();

    int nr_workers = 1; //TODO: provide nr_workers from env var
    thread_fn(nr_workers);
#endif
}


void dest(){
#ifdef CROSSLAYER
	unset_crosslayer();
#endif

#if defined PREDICTOR && !defined __NO_BG_THREADS
    debug_print("application termination...\n");

    clean_state();

    print_readahead_time();
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
        debug_print("Unable to get rusage\n");
    }

    printf("MaxRSS= %lu KB, "
            "SharedMem= %lu KB, "
            "HardPageFault= %lu\n"
            , Hello.ru_maxrss, Hello.ru_ixrss, Hello.ru_majflt);

    syscall(__NR_start_trace, PRINT_PVT_LRU_STATS, 0);
    syscall(__NR_start_trace, PRINT_PPROC_PAGESTATS, 0);
#endif
}


FILE *fopen(const char *filename, const char *mode){

    FILE *ret;
    ret = real_fopen(filename, mode);
    if(!ret)
        return ret;

#ifdef PREDICTOR
    debug_print("%s: TID:%ld open:%s\n", __func__, gettid(), filename);

    int fd = fileno(ret);
    if(reg_file(ret)){
        handle_open(fd, filename);
    }
#endif

    return ret;
}


size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream){

    // Perform the actual system call
    size_t amount_read = real_fread(ptr, size, nmemb, stream);

#ifdef PREDICTOR
    debug_print("%s: TID:%ld\n", __func__, gettid());

    int fd = fileno(stream); 
    if(reg_file(stream)){ //this is a regular file
        ////lseek doesnt work with f* commands
        
        handle_read(fd, ftell(stream), size*nmemb);
    }
#endif
    return amount_read;
}


ssize_t read(int fd, void *data, size_t size){

    ssize_t amount_read = real_read(fd, data, size);

#ifdef PREDICTOR
    debug_print("%s: TID:%ld\n", __func__, gettid());

    if(reg_fd(fd)){
        //printf("fd: %d lseek: %ld bytes: %lu\n", fd, lseek(fd, 0, SEEK_CUR), size );
        handle_read(fd, lseek(fd, 0, SEEK_CUR), size);
    }
#endif

    return amount_read;
}



#if 1
ssize_t pread(int fd, void *data, size_t size, off_t offset){

    ssize_t amount_read = real_pread(fd, data, size, offset);
#ifdef PREDICTOR
    debug_print("%s: TID:%ld\n", __func__, gettid());

    if(reg_fd(fd)){
        handle_read(fd, offset, size);
    }
#endif
    return amount_read;
}
#endif


size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){ 

    // Perform the actual system call
    size_t amount_written = real_fwrite(ptr, size, nmemb, stream);

#ifdef PREDICTOR
    debug_print("%s: TID:%ld\n", __func__, gettid());

    /*XXX: handle after read_write will probably
     * change the ftell position in file*/
    int fd = fileno(stream);
    if(reg_fd(fd)){
        handle_write(fd, ftell(stream), size*nmemb);
    }
#endif

    return amount_written;
}


ssize_t write(int fd, const void *data, size_t size){

    ssize_t amount_written = real_write(fd, data, size);

#ifdef PREDICTOR
    debug_print("%s: TID:%ld\n", __func__, gettid());

    /*XXX: handle after read_write will probably
     * change the lseek position in file*/
    if(reg_fd(fd)){
        handle_write(fd, lseek(fd, 0, SEEK_CUR), size);
    }
#endif
    return amount_written;
}

int fclose(FILE *stream){
#ifdef PREDICTOR
    int fd = fileno(stream);
    debug_print("%s PID:%d fd:%d\n", __func__, getpid(), fd);

    if(reg_file(stream)){
        handle_close(fd);
    }
#endif
    return real_fclose(stream);
}


int close(int fd){

#ifdef PREDICTOR
    debug_print("%s: TID:%ld\n", __func__, gettid());

    if(reg_fd(fd)){
        //remove from the predictor data
        handle_close(fd);
    }
#endif

    return real_close(fd);
}


#ifdef PREDICTOR
int reg_file(FILE *stream){
    return reg_fd(fileno(stream));
}

//returns true if fd is regular file
bool reg_fd(int fd){
    if(fd<=2)
        return false;

    struct stat st;

    if(fstat(fd, &st) == 0){
        switch (st.st_mode & S_IFMT) {
           case S_IFBLK:
               debug_print("fd:%d block device\n", fd);
               break;
           case S_IFCHR:
               debug_print("fd:%d character device\n", fd);
               break;
           case S_IFDIR:
               debug_print("fd:%d directory\n", fd);
               break;
           case S_IFIFO:
               debug_print("fd:%d FIFO/pipe\n", fd);
               break;
           case S_IFLNK:
               debug_print("fd:%d symlink\n", fd);
               break;
           case S_IFREG:
               debug_print("fd:%d regular file\n", fd); 
               return true;            
               break;
           case S_IFSOCK:
               debug_print("fd:%d socket\n", fd);
               break;
           default:
               debug_print("fd:%d unknown?\n", fd);
           }
        /*
        if(S_ISREG(st.st_mode)){
            return true;
        }
        */
    }
    //return true;
    return false;
}
#endif
