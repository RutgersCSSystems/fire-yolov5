#ifndef _UTIL_HPP
#define _UTIL_HPP

#ifndef FILESZ
#define FILESZ 10L
#endif
#define FILESIZE (FILESZ * 1024L * 1024L * 1024L)

#define gettid() syscall(SYS_gettid)

#define BASE_FILENAME "bigfakefile"

#define FILENAMEMAX 1024

/*
 * User request for readaheads with read
 * see pread_ra SYSCALL in fs/read_write.c
 */
struct read_ra_req {
    loff_t ra_pos;
    size_t ra_count;

    /*The following are return values from the OS
     * Reset at recieving them
     */
    unsigned long nr_present; //nr pages present in cache
    unsigned long bio_req_nr;//nr pages requested bio for

//#ifdef CONFIG_CACHE_LIMITING
    long total_cache_usage; //total cache usage in bytes (OS return)
    bool full_file_ra; //populated by app true if pread_ra is being done to get full file
    long cache_limit; //populated by the app, desired cache_limit
//#endif
};


/*
 * Given the mpi rank and the initial string, this
 * function returns the filename per mpi rank
 */
void file_name(const char *str1, int rank, char *buffer){
        char *num;

        if (asprintf(&num, "%dGB", rank) == -1) {
                perror("asprintf");
        } else {
                strcat(strcpy(buffer, str1), num);
                strcat(buffer, ".txt");
                printf("%s\n", buffer);
                free(num);
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


#endif
