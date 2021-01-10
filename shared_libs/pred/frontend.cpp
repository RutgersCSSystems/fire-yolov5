//#define _GNU_SOURCE

#include <dlfcn.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <iostream>
#include <iterator>
#include <algorithm>
#include <map>
#include <deque>
#include <unordered_map>
#include <string>
#include <cstdlib>
#include <ctime>
#include <sys/sysinfo.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fstream>
#include <sys/syscall.h>
#include <sys/types.h>

#include "frontend.hpp"
#include "predictor.hpp"

//#include "ngram.hpp"


size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream)
{

#ifdef DEBUG
    std::cout << "fread" << std::endl;
#endif
    size_t amount_read;

    // Perform the actual system call
    amount_read = real_fread(ptr, size, nmemb, stream);


    int fd; 

    if(fd = reg_file(stream)) //this is a regular file
    {
        handle_read(fd, lseek(fd, 0, SEEK_CUR), size*nmemb);
    }

    return amount_read;
}

ssize_t read(int fd, void *data, size_t size)
{
#ifdef DEBUG
    printf("Hello read\n");
#endif
    ssize_t amount_read = real_read(fd, data, size);

    if(reg_fd(fd))
    {
        handle_read(fd, lseek(fd, 0, SEEK_CUR), size);
    }

    return amount_read;
}

size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream)
{
    // Perform the actual system call
    size_t amount_written = real_fwrite(ptr, size, nmemb, stream);

#ifdef PREDICTOR
    int fd;
    if(fd = reg_file(stream))
    {
        //insert to the predictor
        handle_write(fd, lseek(fd, 0, SEEK_CUR), size*nmemb);
    }
#endif

    return amount_written;
}


ssize_t write(int fd, const void *data, size_t size)
{
#ifdef DEBUG
    printf("writes\n");
#endif

    // Perform the actual system call
    ssize_t amount_written = real_write(fd, data, size);

#ifdef PREDICTOR
    //DO we need to take care of what results we get from the real call ?
    if(reg_fd(fd))
    {
        //do somthign
        handle_write(fd, lseek(fd, 0, SEEK_CUR), size);
    }
#endif
    return amount_written;
}

int fclose(FILE *stream)
{
#ifdef DEBUG
    printf("fclose detected\n");
#endif

#ifdef PREDICTOR
    int fd;
    if(fd = reg_file(stream))
    {
        handle_close(fd);
    }
#endif
    return real_fclose(stream);
}


int close(int fd)
{
#ifdef DEBUG
    printf("File close detected\n");
#endif

#ifdef PREDICTOR
    if(reg_fd(fd))
    {
        //remove from the predictor data
        handle_close(fd);
    }
#endif
    return real_close(fd);
}

//returns fd if  FILE is a regular file
int reg_file(FILE *stream)
{
    struct stat st;
    int fd = fileno(stream);

    if(fstat(fd, &st) == 0)
    {
        if(S_ISREG(st.st_mode))
        {
            return fd;
        }
    }
    return false;
}

//returns true if fd is regular file
bool reg_fd(int fd)
{
    struct stat st;

    if(fstat(fd, &st) == 0)
    {
        if(S_ISREG(st.st_mode))
        {
            return true;
        }
    }
    return false;
}
