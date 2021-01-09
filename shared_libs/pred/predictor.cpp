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

#include "ngram.hpp"


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


size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream){

    size_t amount_read;

    // Perform the actual system call
    amount_read = real_fread(ptr, size, nmemb, stream);

    int fd = fileno(stream);
    off_t pos = -1;

    if()

#ifdef PREDICTOR
			 read_predictor(fd, pos, size*nmemb);
#endif
		  }
	   }
    }
#ifdef PATTERN
    access_pattern(fd, pos, size*nmemb, 0);
#endif

    return amount_read;
}
