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
        unsigned long read_time; //Return value, time taken to read the file in microsec
        char filename[FILENAMEMAX]; //filename for opening that file
};


//Given an array, it shuffles it
//using Fisher–Yates shuffle (also known as Knuth's Shuffle)
//To be used for Random Reads
void shuffle(long int array[], size_t n) {
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

        struct thread_args *a = (struct thread_args*)arg;

        struct timeval start, end;
        size_t buff_sz = (PG_SZ * a->nr_read_pg);
        char *buffer = (char*) malloc(buff_sz);

        size_t readnow, bytes_read, offset, ra_offset;

        long tid = gettid();

#if SHARED_FILE
        a->fd = open(a->filename, O_RDWR);
        if (a->fd == -1){
                printf("\n File %s Open Unsuccessful: TID:%ld\n", a->filename, tid);
                exit(0);
        }
#endif

#ifdef DEBUG
        //Report about the thread
        printf("TID:%ld: going to fetch from %ld for size %ld on file %d, read_pg = %ld\n",
                        tid, a->offset, a->size, a->fd, a->nr_read_pg);
#endif //DEBUG

#ifdef READ_SEQUENTIAL

        gettimeofday(&start, NULL);
        bytes_read = 0UL;
        offset = a->offset;

#ifdef APP_SINGLE_PREFETCH
	readahead(a->fd, offset, a->size);
#ifdef DEBUG
			printf("%s: readahead called for fd:%d, offset=%ld, bytes=%ld\n",
					__func__, a->fd, offset, a->size);
#endif
#elif defined(APP_OPT_PREFETCH)
	ra_offset = a->offset;
#endif

        while(bytes_read < a->size){


#ifdef DEBUG
                printf("%s:%ld fd=%d bytes_read=%ld, offset=%ld, size=%ld\n", __func__, tid, a->fd, bytes_read, offset, buff_sz);
#endif //DEBUG

#ifdef APP_OPT_PREFETCH
		if(offset >= ra_offset){
			ra_offset = offset;
			readahead(a->fd, ra_offset, NR_RA_PAGES << PAGESHIFT);
			ra_offset += NR_RA_PAGES << PAGESHIFT;
#ifdef DEBUG
			printf("%s: readahead called for fd:%d, offset=%ld, bytes=%ld\n",
					__func__, a->fd, ra_offset, NR_RA_PAGES << PAGESHIFT);
#endif
		}
#endif

                readnow = pread(a->fd, ((char *)buffer),
                                        buff_sz, offset);
                if(readnow < 0){
                        printf("\nRead Unsuccessful\n");
                        free(buffer);
                        goto exit;
                }
                bytes_read += readnow;

                offset += readnow;
#ifdef STRIDED_READ
                offset += NR_STRIDE * PG_SZ;
#endif //STRIDED_READ
                //usleep(1);
        }
        gettimeofday(&end, NULL);

#elif READ_RANDOM

        size_t nr_file_portions = a->size/buff_sz;
        long *read_sequence = (long*)malloc(sizeof(long)*nr_file_portions);

        for(long i=0; i<nr_file_portions; i++){
                read_sequence[i] = i;
        }
        shuffle(read_sequence, nr_file_portions);

        gettimeofday(&start, NULL);

        for(long i=0; i<nr_file_portions; i++){
                readnow = pread(a->fd, ((char *)buffer),
                                        buff_sz, (read_sequence[i]*buff_sz)+a->offset);
        }

        gettimeofday(&end, NULL);
#endif

        a->read_time = usec_diff(&start, &end);
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
        char filename[FILENAMEMAX];
        int fd = -1;

        for(int i=0; i<NR_THREADS; i++){
#ifdef SHARED_FILE
                file_name(i, filename, 1);
                goto skip_open;
#else
                file_name(i, filename, NR_THREADS);
#endif
                fd = open(filename, O_RDWR);
                if (fd == -1){
                        printf("\nFile %s Open Unsuccessful\n", filename);
                        exit (0);
                }
                fd_list.push_back(fd);
                fd = -1;
#ifdef SHARED_FILE
                //Open just one file since shared
                break;
#endif
        }

        //Done opening all files
skip_open:


//Disables OS pred
#if defined(ONLYAPP) && !defined(SHARED_FILE)
        for(int i=0; i<NR_THREADS; i++){
                posix_fadvise(fd_list[i], 0, 0, POSIX_FADV_RANDOM);
        }
#endif


        threadpool thpool;
        thpool = thpool_init(NR_THREADS); //spawns a set of worker threads
        if(!thpool){
                printf("FAILED: creating threadpool with %d threads\n", NR_THREADS);
        }


        //Preallocating all the thread_args to remove overheads
        struct thread_args *req = (struct thread_args*)
                                malloc(sizeof(struct thread_args)*NR_THREADS);



        for(int i=0; i<NR_THREADS; i++){

                req[i].size = FILESIZE/NR_THREADS;
                req[i].nr_read_pg = NR_PAGES_READ;
                req[i].read_time = 0UL;

#ifdef SHARED_FILE
                //req[i].fd = fd_list[0];
                req[i].fd = -1;
                strcpy(req[i].filename, filename);
                req[i].offset = req[i].size*i; //Start at different position
#else
                req[i].fd = fd_list[i]; //assign one file to each worker thread
                req[i].offset = 0;
#endif

                thpool_add_work(thpool, reader_th, (void*)&req[i]);
        }

        thpool_wait(thpool);

        //Print the Throughput
        
        long size_mb;
        float max_time = 0.f; //in sec
        float time;

#ifdef STRIDED_READ
        long nr_file_pg = FILESIZE/PG_SZ;
        long nr_read_stride_blocks = nr_file_pg/(NR_PAGES_READ+NR_STRIDE);
        size_mb = (nr_read_stride_blocks * NR_PAGES_READ * PG_SZ)/(1024L*1024L);
#else
        size_mb = FILESIZE/(1024L*1024L);
#endif
        printf("Total File size = %ld MB\n", size_mb);
        for(int i=0; i<NR_THREADS; i++){
                time = req[i].read_time/1000000.f;
                if(max_time < time)
                        max_time = time;
        }
#if defined(READ_SEQUENTIAL) && defined(STRIDED_READ)
        printf("READ_STRIDED Bandwidth = %.2f MB/sec\n", size_mb/max_time);
#elif defined(READ_SEQUENTIAL) && !defined(STRIDED_READ)
        printf("READ_SEQUENTIAL Bandwidth = %.2f MB/sec\n", size_mb/max_time);
#elif READ_RANDOM
        printf("READ_RANDOM Bandwidth = %.2f MB/sec\n", size_mb/max_time);
#endif
        return 0;
}
