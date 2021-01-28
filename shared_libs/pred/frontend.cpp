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

#include "frontend.hpp"
#include "predictor.hpp"
#include "worker.hpp"

//#include "ngram.hpp"
//
static void con() __attribute__((constructor));
static void dest() __attribute__((destructor));


void con()
{
    //struct sigaction action;

    fprintf(stderr, "init tracing...\n");
    
    //initialize a worker thread
    thread_fn();

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
