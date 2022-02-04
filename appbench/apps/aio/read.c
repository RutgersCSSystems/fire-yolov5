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

#define NR_PAGES_READ 10
#define NR_PAGES_RA 20
#define PG_SZ 4096

#ifdef FILESZ
#define FILESIZE (FILESZ * 1024L * 1024L * 1024L)
#else
#define FILESIZE (10L * 1024L * 1024L * 1024L)
#endif


struct thread_args{
    int fd;
};

void *prefetcher_th(void *arg){

    struct thread_args *a = (struct thread_args*)arg;
    printf("Printing from thread %s, %d\n", __func__, a->fd);

    char *buffer = (char*) malloc(buff_sz*sizeof(char));
    off_t chunk = 0;
    long nr_read = 0; //controls the readaheads
    size_t readnow;

    struct aiocb cb;
    memset(&cb, 0, sizeof(struct aiocb));

    cb.aio_filedes = a->fd;
    cb.aio_offset

    while (chunk < size){

        readnow = pread(fd, ((char *)buffer), 
                PG_SZ*NR_PAGES_READ, chunk);

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



    return NULL;
}

//returns microsecond time difference
unsigned long usec_diff(struct timeval *a, struct timeval *b)
{
    unsigned long usec;

    usec = (b->tv_sec - a->tv_sec)*1000000;
    usec += b->tv_usec - a->tv_usec;
    return usec;
}

int main(int argc, char **argv)
{
    long size = FILESIZE;
    long buff_sz = (PG_SZ * NR_PAGES_READ);

    struct timeval start, end;

    char *buffer = (char*) malloc(buff_sz*sizeof(char));
    off_t chunk = 0;
    long nr_read = 0; //controls the readaheads

    int fd = open("bigfakefile.txt", O_RDWR);
    if (fd == -1){
        printf("\nFile Open Unsuccessful\n");
        exit (0);
    }

    pthread_t thread_id;
    struct thread_args req;
    req.fd = fd;
    pthread_create(&thread_id, NULL, prefetcher_th, &req);

    gettimeofday(&start, NULL);
    while ( chunk < size ){
        size_t readnow;

        readnow = pread(fd, ((char *)buffer), 
                PG_SZ*NR_PAGES_READ, chunk);

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
    
    
    pthread_join(thread_id, NULL);

    unsigned long usec = usec_diff(&start, &end);
    printf("Reading done in %ld microsecs\n", usec);
    return 0;
}
