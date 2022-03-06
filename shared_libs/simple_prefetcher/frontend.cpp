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


    printf("Opening file\n");

exit:
    return fd;
}


FILE *fopen(const char *filename, const char *mode){
    int fd;

    FILE *ret;
    ret = real_fopen(filename, mode);
    if(!ret)
        return ret;

    fd = fileno(ret);

    printf("FOpening file\n");

    return ret;
}
