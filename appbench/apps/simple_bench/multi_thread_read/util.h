#ifndef _UTIL_HPP
#define _UTIL_HPP

#define PG_SZ 4096L
#define PAGESHIFT 12L

#ifndef NR_THREADS //Nr of BG readahead threads
#define NR_THREADS 1
#endif

/*
 * NR of pages to skip after each read
 */
#ifndef NR_STRIDE
#define NR_STRIDE 50
#endif

/*
 * Size of file in GB
 */
#ifdef FILESZ
#define FILESIZE (FILESZ * 1024L * 1024L * 1024L)
#else
#define FILESIZE (10L * 1024L * 1024L * 1024L)
#endif

//Number of pages to read in one pread syscall
#ifndef NR_PAGES_READ
#define NR_PAGES_READ 10
#endif

#ifndef NR_RA_PAGES
#define NR_RA_PAGES 256L
#endif

#define FILEBASE "bigfakefile"

#define gettid() syscall(SYS_gettid)

#define FILENAMEMAX 1024


void folder_name(char *buffer, int nr_files){
        char *nr_threads;
        const char* str1 = "./threads_";

        if (asprintf(&nr_threads, "%d", nr_files) == -1) {
                perror("asprintf");
        } else {
                strcat(strcpy(buffer, str1), nr_threads);
                free(nr_threads);
        }
}
/*
 * Given the mpi rank and the initial string, this
 * function returns the filename per mpi rank
 */
void file_name(int rank, char *buffer, int nr_files){
        char *num;
        char *nr_threads;

        const char* str1 = "./threads_";

        if (asprintf(&num, "%d", rank) == -1 || asprintf(&nr_threads, "%d", nr_files) == -1) {
                perror("asprintf");
        } else {
                strcat(strcpy(buffer, str1), nr_threads);
                strcat(buffer, "/");
                strcat(buffer, FILEBASE);
                strcat(buffer, num);
                strcat(buffer, ".txt");
                free(num);
                free(nr_threads);
        }
}


//returns microsecond time difference
unsigned long usec_diff(struct timeval *a, struct timeval *b)
{
    unsigned long usec;

    usec = (b->tv_sec - a->tv_sec)*1000000;
    usec += b->tv_usec - a->tv_usec;
    return usec;
}


//Returns the aggregate throughput experienced in MB/sec
double throughput(struct timeval *a, struct timeval *b, unsigned long filesize){
        
        double throughput = 0.0;
        

        //TODO Complete the algorithm

        return throughput;
}

#endif
