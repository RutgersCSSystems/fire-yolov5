#define _LARGEFILE64_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


#define FILENAME "testfile.txt"
#define PAGESIZE 4096


#ifndef NR_PAGES
#define NR_PAGES 2
#endif

int main(){
        int fd;
        char *buffer = (char*)malloc(sizeof(PAGESIZE));
        fd = open(FILENAME, O_CREAT | O_RDWR, S_IWUSR | S_IRUSR | S_IXUSR);


        for(int i=0; i<PAGESIZE; i++){
                buffer[i] = 'c';
        }


        for(int i=0; i<NR_PAGES; i++){
                pwrite(fd, buffer, PAGESIZE, i*PAGESIZE);
        }

        return 0;
}
