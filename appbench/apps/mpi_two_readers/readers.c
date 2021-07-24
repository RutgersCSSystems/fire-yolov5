#define _GNU_SOURCE
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <mpi.h>

#define FILE_SIZE (20L * 1024L * 1024L * 1024L)
#define SLENGTH 64
#define MAX_READAHEAD (128L * 1024L)

#ifdef DEBUG
#define debug_print(...) printf(__VA_ARGS__ )
//#define debug_print(...) fprintf( stderr, __VA_ARGS__ )
#else
#define debug_print(...) do{ }while(0)
#endif


int num_proc, my_id;
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

    if(my_id == 0)
    {
        int fd = fileno(file);
#ifdef STRIDE
        for(int i=0; i<nr_loops; i+=STRIDE)
#else
        for(int i=0; i<nr_loops; i+=1)
#endif
        {
            long offset = i * MAX_READAHEAD;
#ifdef READAHEAD
            readahead(fd, offset, MAX_READAHEAD);
            debug_print("readahead %ld\n", i*MAX_READAHEAD);
#elif defined READ
            fseeko64(file, offset, SEEK_SET);
            int a = fread(out, sizeof(int), nr_ints, file);
#endif
        }
    }
    else
    {
        int j=0;
#if defined FORWARD && defined STRIDE
        for(int j=0; j<=STRIDE; j++)
        {
            for(int i=j; i<nr_loops/2; i+=STRIDE)
#elif defined BACKWARD && defined STRIDE
        for(int j=STRIDE; j>=0; j--)
        {
            for(int i=j; i<nr_loops; i+=STRIDE)
#else
        {
            for(int i=j; i<nr_loops; i+=1)
#endif
            {
                long offset = i * MAX_READAHEAD;
                fseeko64(file, offset, SEEK_SET);
                debug_print("read at location %ld\n", offset);

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
    MPI_Init(&argc, &argv);
    MPI_Comm_size(MPI_COMM_WORLD, &num_proc);
    MPI_Comm_rank(MPI_COMM_WORLD, &my_id);

    int a = readit();
    printf("sum = %d from proc %d\n", a, my_id);
    PMPI_Barrier(MPI_COMM_WORLD);

    MPI_Finalize();
    return 0;
}
