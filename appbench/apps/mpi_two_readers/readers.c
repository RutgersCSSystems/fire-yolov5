#define _GNU_SOURCE
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <mpi.h>

#define FILE_SIZE (20L * 1024L * 1024L * 1024L)
#define SLENGTH 64
#define MAX_READAHEAD (128L * 1024L)

int num_proc, my_id;
FILE *file; //datafile
char filename[SLENGTH] = "datafile";


int readit()
{
    int sum;
    int *out = (int *) malloc(MAX_READAHEAD);
    file = fopen(filename, "rw");
    if(file == NULL)
        printf("couldnt open file \n");

    if(my_id == 0)
    {
        int fd = fileno(file);
        posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
    }

    int nr_loops = FILE_SIZE/MAX_READAHEAD;
    if(my_id == 0)
    {
        int fd = fileno(file);
        for(int i=1; i<nr_loops; i++)
        {
            readahead(fd, i*MAX_READAHEAD, MAX_READAHEAD);
        }
    }
    else
    {
        int nr_ints = MAX_READAHEAD/sizeof(int);
        for(int i=0; i<nr_loops; i++)
        {
            int a = fread(out, sizeof(int), nr_ints, file);
            if(a != nr_ints)
            {
               // printf("a  not eqyal\n");
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
    }
    return sum;
}

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    MPI_Comm_size(MPI_COMM_WORLD, &num_proc);
    MPI_Comm_rank(MPI_COMM_WORLD, &my_id);

    int a = readit();
    printf("sum = %d\n", a);
    PMPI_Barrier(MPI_COMM_WORLD);

    return 0;
}
