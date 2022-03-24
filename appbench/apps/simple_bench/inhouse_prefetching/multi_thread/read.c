/*/
 * This program will have two threads.
 * Master Thread is going to read the file Sequentially using pread syscall.
 * Slave Thread is going to prefetch the contents using aio_read syscall.
 * We will switch off OS prefetching to understand if AIO is reducing wait times.
 */
#define _LARGEFILE64_SOURCE
#define _GNU_SOURCE
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

#include "util.h"
#include "utils/thpool.h"

#define NR_PAGES_READ 10
#define PG_SZ 4096L

#ifdef NR_RA_PAGES
#define NR_PAGES_RA NR_RA_PAGES
#else
#define NR_PAGES_RA 40
#endif

/*
 * Number of pages to read with pread_ra
 * when prefetching using PREFETCH_PREAD_RA
 */
#ifndef READ_PG_PREAD_RA
#define READ_PG_PREAD_RA 0
#endif

#ifndef NR_BG_THREADS //Nr of BG readahead threads
#define NR_BG_THREADS 1
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

#ifdef PREFETCH_READ
        char *buffer = (char*) malloc(a->buff_sz);
#elif PREFETCH_PREAD_RA
	int READ_PG = READ_PG_PREAD_RA; //nr of pages to read while doing pread_ra
     	char *buffer = (char*) malloc(PG_SZ*READ_PG);

	struct read_ra_req ra_req;
	memset(&ra_req, 0, sizeof(struct read_ra_req));
#endif

        while (chunk < a->size){
                //printf("TID:%ld, chunk=%ld, buff_size=%ld\n", tid, (chunk+a->offset), a->buff_sz);
#ifdef PREFETCH_READAHEAD
                if(readahead(a->fd, (chunk+a->offset), a->buff_sz) > 0){
                        printf("error while readahead \n");
                        return;
                }
#elif PREFETCH_READ
                readnow = read(a->fd, ((char *)buffer), a->buff_sz);
                if (readnow < 0 ){
                        printf("\nRead in prefetcher %ld Unsuccessful\n", tid);
                        free (buffer);
                        return;
                }
#elif PREFETCH_PREAD_RA
		ra_req.ra_pos = 0; //Will ra start where the read is happening
		ra_req.ra_count = a->buff_sz ;
		readnow = syscall(449, a->fd, ((char *)buffer),
				PG_SZ*READ_PG, (chunk+a->offset), &ra_req);
#endif
                chunk += a->buff_sz;
        }
}


int main(int argc, char **argv)
{
        long size = FILESIZE;
        long buff_sz = (PG_SZ * NR_PAGES_READ);

        struct timeval start, end;

        char *buffer = (char*) malloc(buff_sz);
        off_t chunk = 0;
        long nr_read = 0; //controls the readaheads

        const char* str1 = BASE_FILENAME;
        char filename[FILENAMEMAX];
        file_name(str1, FILESZ, filename);

        int fd = open(filename, O_RDWR);
        if (fd == -1){
                printf("\nFile Open Unsuccessful\n");
                exit (0);
        }

        struct read_ra_req ra_req;

#ifdef ONLYAPP
        //Disables OS pred
        posix_fadvise(fd, 0, 0, POSIX_FADV_RANDOM);
#endif

#ifdef CONCURRENT_PREFETCH
        //pthread_create(&thread_id, NULL, prefetcher_th, &req);
        threadpool thpool;
        thpool = thpool_init(NR_BG_THREADS); //spawns a set of bg threads
        if(!thpool){
                printf("FAILED: creating threadpool with %d threads\n", NR_BG_THREADS);
        }
        else {
             	fprintf(stderr, "Created %d bg threads\n", NR_BG_THREADS);
	}

        for(int i=0; i<NR_BG_THREADS; i++){
                struct thread_args *req = (struct thread_args*)malloc(sizeof(struct thread_args));
                req->fd = fd;
                req->size = FILESIZE/NR_BG_THREADS;
                req->offset = i*req->size;
#ifdef FULL_RA
                req->buff_sz = req->size;//Size of each prefetch
#else
                req->buff_sz = PG_SZ * NR_PAGES_RA; //Size of each prefetch
#endif
                thpool_add_work(thpool, prefetcher_th, (struct thread_args*)req);
        }
        //fprintf(stderr, "nr of threads working right now %d\n", thpool_num_threads_working(thpool));
#endif

#ifndef DONT_READ_FILE
        gettimeofday(&start, NULL);
        while ( chunk < size ){
                size_t readnow;

                //printf("MASTER: reading at offset %ld\n", chunk);

#ifdef PREAD_RA
	      ra_req.ra_count = NR_PAGES_RA;
	      ra_req.ra_pos = 0;
	      readnow = syscall(449, fd, ((char *)buffer), 
				PG_SZ*NR_PAGES_READ, chunk, &ra_req);
#else
              readnow = pread(fd, ((char *)buffer), 
                              PG_SZ*NR_PAGES_READ, chunk);
#endif
                if (readnow < 0 ){
                        printf("\nRead Unsuccessful\n");
                        free (buffer);
                        close (fd);
                        return 0;
                }
                chunk += readnow; //offset
                nr_read += NR_PAGES_READ;
        }
        gettimeofday(&end, NULL);
#endif


#if defined(CONCURRENT_PREFETCH) && defined(DONT_READ_FILE)
	printf("Waiting in the thread pool\n");
        thpool_wait(thpool);
	printf("Exiting the thread pool\n");
        //forced_thpool_destroy(thpool);
        //pthread_cancel(thread_id);
        //pthread_join(thread_id, NULL);
#endif

#ifndef DONT_READ_FILE
        unsigned long sec = sec_diff(&start, &end);
        printf("Reading done in %ld secs\n", sec);
#endif
        return 0;
}
