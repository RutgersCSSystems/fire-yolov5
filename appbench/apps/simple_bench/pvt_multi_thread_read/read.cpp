/*/
 * This program will have NR_THREADS + 1 threads.
 * Each worker Thread is going to read a pvt file Sequentially/Randomly using pread syscall.
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
#include <random>

#include "util.h"
#include "utils/thpool.h"

using namespace std;


struct thread_args{
        int fd; //fd of opened file
        long size; //bytes to fetch from this thread
        long nr_read_pg; //nr of pages to read each req
        size_t offset; //Offset of file where RA to start from
        int read_time; //Return value, time taken to read the file
};

//Given an array, it shuffles it
//using Fisher–Yates shuffle (also known as Knuth's Shuffle)
//To be used for Random Reads
void shuffle(int array[], size_t n) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    int usec = tv.tv_usec;
    srand48(usec);

    if (n > 1) {
        size_t i;
        for (i = n - 1; i > 0; i--) {
            size_t j = (unsigned int) (drand48()*(i+1));
            int t = array[j];
            array[j] = array[i];
            array[i] = t;
        }
    }
}



//Will be reading one pvt file per thread
void reader_th(void *arg){

        struct timeval start, end;
        struct thread_args *a = (struct thread_args*)arg;

#ifdef DEBUG
        long tid = gettid();
        printf("TID:%ld: going to fetch from %ld for size %ld on file %d, read_pg = %ld\n",
                        tid, a->offset, a->size, a->fd, a->nr_read_pg);
#endif

        a->read_time = 123; //XXX: Sort this out

        //size_t buff_sz = (PG_SZ * a->nr_read_pg);
        //char *buffer = (char*) malloc(buff_sz);

        //gettimeofday(&start, NULL);

        //gettimeofday(&end, NULL);

#if 0
#ifdef READ_SEQUENTIAL

#elif READ_RANDOM

#endif

        off_t chunk = 0;
        size_t readnow;

        while (chunk < a->size){
#ifdef DEBUG
                printf("TID:%ld, chunk=%ld, read_pg=%ld\n", tid, (chunk+a->offset), a->nr_read_pg);
#endif
                if(readahead(a->fd, (chunk+a->offset), (a->nr_read_pg*PG_SZ)) > 0){
                        printf("error while readahead \n");
                        return;
                }
                chunk += a->
        }
#endif 

exit:
        return;
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

        for(int i=0; i<NR_THREADS; i++){
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


//Disables OS pred
#ifdef ONLYAPP
        for(int i=0; i<NR_THREADS; i++){
                posix_fadvise(fd_list[i], 0, 0, POSIX_FADV_RANDOM);
        }
#endif


        threadpool thpool;
        thpool = thpool_init(NR_THREADS); //spawns a set of worker threads
        if(!thpool){
                printf("FAILED: creating threadpool with %d threads\n", NR_THREADS);
        }
        else
                printf("Created %d bg threads\n", NR_THREADS);


        //Preallocating all the thread_args to remove overheads
        struct thread_args *req = (struct thread_args*)
                                malloc(sizeof(struct thread_args)*NR_THREADS);



        for(int i=0; i<NR_THREADS; i++){
                req[i].fd = fd_list[i]; //assign one file to each worker thread
                req[i].size = FILESIZE/NR_THREADS;
                req[i].offset = 0;
                req[i].nr_read_pg = NR_PAGES_READ;
                req[i].ret = 0;
                thpool_add_work(thpool, reader_th, (void*)&req[i]);
        }


#if 0
        ////////////////////////////////////////

        char *buffer = (char*) malloc(buff_sz);
        off_t local_offset = 0; //
        off_t global_offset = 0; //aggregate file size read till now
        size_t readnow;
        int newfd;

        while ( global_offset < size ){

                newfd = fd_list[floor((global_offset*NR_THREADS)/FILESIZE)];
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
#endif


        thpool_wait(thpool);

        for(int i=0; i<NR_THREADS; i++){
                //Calculate the Bandwidth based on time taken to read from each thread
                printf("ret = %d\n", req[0].ret);
        }

        unsigned long usec = usec_diff(&start, &end);
        //Get Throughput
        printf("Reading done in %ld microsecs\n", usec);
        return 0;
}
