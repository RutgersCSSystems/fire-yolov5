/*
 * This program reads a file sequentially in two ways:
 * 1. FORWARD: from 0 to EOF
 * 2. BACKWARD: from EOF to 0
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>

#define FILE_SIZE (20L * 1024L * 1024L * 1024L)
#define SLENGTH 64
#define MAX_READAHEAD (128L * 1024L) //128KB

FILE *file; //datafile
char filename[SLENGTH] = "datafile";

int readit(){
    int sum;
    int *out = (int *) malloc(MAX_READAHEAD);

    file = fopen(filename, "rw");
    if(file == NULL)
        printf("couldnt open file \n");

#ifdef CLEAR_CACHE
    /*clear cache inside the program*/
    if(my_id == 0)
    {
        int fd = fileno(file);
        posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
    }
    PMPI_Barrier(MPI_COMM_WORLD);
#endif

    int nr_loops = FILE_SIZE/MAX_READAHEAD;
    int nr_ints = MAX_READAHEAD/sizeof(int);
    size_t offset;

    /*
    fseeko64(file, 0L, SEEK_END);
    size_t file_size = ftell(file);
    fseeko64(file, 0L, SEEK_SET);
    */

#ifdef BACKWARD
    //for(size_t j=file_size-MAX_READAHEAD; j>=0L; j-=MAX_READAHEAD)
    for(size_t j=nr_loops-1; j>=0L; j-=1)
#else
    for(size_t j=0L; j<nr_loops; j+=1)
#endif
    {
        offset = j * MAX_READAHEAD;
        fseeko64(file, offset, SEEK_SET);
        int a = fread(out, sizeof(int), nr_ints, file);
        if(a != nr_ints)
        {
            if (feof(file))
                printf("Error reading test.bin: unexpected end of file\n");
            else if (ferror(file)) {
                perror("Error reading test.bin");
            }
            break;
        }
    }


    for(int i=0; i< nr_ints; i++)
    {
        sum += out[i];
    }
    return sum;
}

int main(int argc, char **argv)
{
    int a = readit();
    return 0;
}
