#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define FILENAME "./strided_read.c"
#define STRIDE 10
#define BLOCK_SIZE 20

int main()
{
    char buff[50];
    ssize_t bytes_read=-1;
#ifdef POSIX
    int fd=open(FILENAME, O_RDONLY);
    if(-1 == fd)
    {
        perror("Open Failed");
        return 1;
    }

    while((bytes_read=read(fd, buff, BLOCK_SIZE))>0)
    {
        lseek(fd, STRIDE, SEEK_CUR);
    }

    printf("%s\n", buff);



#endif

#ifdef STDIO
#endif
}
