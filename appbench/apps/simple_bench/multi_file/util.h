#ifndef _UTIL_HPP
#define _UTIL_HPP

#ifndef NR_BG_THREADS //Nr of BG readahead threads
#define NR_BG_THREADS 1
#endif

#define gettid() syscall(SYS_gettid)

#define FILENAMEMAX 1024

/*
 * Given the mpi rank and the initial string, this
 * function returns the filename per mpi rank
 */
void file_name(const char *str1, int rank, char *buffer){
        char *num;

        if (asprintf(&num, "%d", rank) == -1) {
                perror("asprintf");
        } else {
                strcat(strcpy(buffer, str1), num);
                strcat(buffer, ".txt");
                printf("%s\n", buffer);
                free(num);
        }
}

#endif
