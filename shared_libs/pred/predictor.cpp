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

#include "predictor.hpp"

//#include "ngram.hpp"


size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream)
{

    size_t amount_read;

    // Perform the actual system call
    amount_read = real_fread(ptr, size, nmemb, stream);

    std::cout << "fread" << std::endl;

    int fd; 

    if(fd = reg_file(stream)) //this is a regular file
    {
        // TODO
    }

    return amount_read;
}

ssize_t read(int fd, void *data, size_t size)
{
    ssize_t amount_read = real_read(fd, data, size);

    printf("Hello read\n");
    if(reg_fd(fd))
    {
    }

    return amount_read;
}


int fclose(FILE *stream){
#ifdef DEBUG
	printf("fclose detected\n");
#endif
	//TODO:call fadvise
#ifdef PREDICTOR
	int fd;
     if(fd = reg_file(stream))
		remove(fd);
#endif
	return real_fclose(stream);
}


int close(int fd){
#ifdef DEBUG
	printf("File close detected\n");
#endif

#ifdef PREDICTOR
	if(reg_fd(fd))
		remove(fd);
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
