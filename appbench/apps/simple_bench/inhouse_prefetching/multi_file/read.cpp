/*/
 * This program will have NR_BG_THREADS + 1 threads.
 * Single Master Thread is going to read the file Sequentially using pread syscall.
 * #NR_BG_THREADS Slave Thread is going to prefetch the contents using readahead syscall.
 */
#define _LARGEFILE64_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <aio.h>
#include <pthread.h>
#include <stdbool.h>
#include <fcntl.h>
#include <errno.h>
#include <stdbool.h>
#include <limits.h>
#include <signal.h>
#include <math.h>
#include <time.h>
#include <sys/types.h>
#include <sys/syscall.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <sys/mman.h>

#include <iostream>
#include <vector>

#include "util.h"
#include "utils/thpool.h"

using namespace std;

#define NR_PAGES_READ 10
#define PG_SZ 4096L

#ifdef NR_RA_PAGES
#define NR_PAGES_RA NR_RA_PAGES
#else
#define NR_PAGES_RA 40
#endif


struct thread_args{
        int fd; //fd of opened file
        long size; //bytes to fetch from this thread
        long buff_sz; //size of each readahead req
        size_t offset; //Offset of file where RA to start from
};

void prefetcher_th(void *arg){
        long tid = gettid();
        struct thread_args *a = (struct thread_args*)arg;
        printf("TID:%ld: going to fetch from %ld for size %ld on file %d, rasize = %ld\n", 
                        tid, a->offset, a->size, a->fd, a->buff_sz);

        off_t chunk = 0;
        size_t readnow;

        while (chunk < a->size){
                //printf("TID:%ld, chunk=%ld, buff_size=%ld\n", tid, (chunk+a->offset), a->buff_sz);
                if(readahead(a->fd, (chunk+a->offset), a->buff_sz) > 0){
                        printf("error while readahead \n");
                        return;
                }
                chunk += a->buff_sz;
        }
}


int main(int argc, char **argv)
{
        long size = FILESIZE;


        /*
         * Open all the files and save their fds
         */
        vector<int> fd_list;
        const char* str1 = "bigfakefile";
        char filename[FILENAMEMAX];
        int fd;

        for(int i=0; i<NR_BG_THREADS; i++){
                file_name(str1, i, filename);
                fd = open(filename, O_RDWR);
                if (fd == -1){
                        printf("\nFile %s Open Unsuccessful\n", filename);
                        exit (0);
                }
                fd_list.push_back(fd);
                fd = -1;
        }
        //Done opening all files


#ifdef ONLYAPP
        //Disables OS pred
        for(int i=0; i<NR_BG_THREADS; i++){
                posix_fadvise(fd_list[i], 0, 0, POSIX_FADV_RANDOM);
        }
#endif


#ifdef PREFETCH
        threadpool thpool;
        thpool = thpool_init(NR_BG_THREADS); //spawns a set of bg threads
        if(!thpool){
                printf("FAILED: creating threadpool with %d threads\n", NR_BG_THREADS);
        }
        else
                printf("Created %d bg threads\n", NR_BG_THREADS);

        for(int i=0; i<NR_BG_THREADS; i++){
                struct thread_args *req = (struct thread_args*)malloc(sizeof(struct thread_args));
                req->fd = fd_list[i]; //assign one file to each worker thread
                req->size = FILESIZE/NR_BG_THREADS;
                req->offset = 0;
                req->buff_sz = PG_SZ * NR_PAGES_RA;
                thpool_add_work(thpool, prefetcher_th, (struct thread_args*)req);
        }
#endif

#ifndef DONT_READ_FILE
        long buff_sz = (PG_SZ * NR_PAGES_READ);
        struct timeval start, end;
        char *buffer = (char*) malloc(buff_sz);
        off_t local_offset = 0; //
        off_t global_offset = 0; //aggregate file size read till now
        size_t readnow;
        int newfd;

        gettimeofday(&start, NULL);
        while ( global_offset < size ){

                newfd = fd_list[floor((global_offset*NR_BG_THREADS)/FILESIZE)];
                if(fd != newfd){
                        fd = newfd;
                        local_offset = 0UL;
                }

                readnow = pread(fd, ((char *)buffer), 
                                PG_SZ*NR_PAGES_READ, local_offset);

                if (readnow < 0 ){
                        printf("\nRead Unsuccessful\n");
                        free(buffer);
                        return 0;
                }
                local_offset += readnow; //offset
                global_offset += readnow; //offset
        }
        gettimeofday(&end, NULL);
#endif


#ifdef PREFETCH
        //forced_thpool_destroy(thpool);
        //pthread_cancel(thread_id);
        //pthread_join(thread_id, NULL);
#endif

#ifndef DONT_READ_FILE
        unsigned long usec = usec_diff(&start, &end);
        printf("Reading done in %ld microsecs\n", usec);
#endif
        return 0;
}
