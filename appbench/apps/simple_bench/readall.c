#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

#include <sys/time.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/stat.h>

#define __NR_start_crosslayer 448

#define NR_PAGES_READ 1
#define NR_PAGES_RA 10000
#define PG_SZ 4096

#define FILESIZE (10L * 1024L * 1024L * 1024L)

int main(){

	int fd;

	fd = open("bigfakefile.txt", O_RDWR);
	if (fd == -1){
		printf("\nFile Open Unsuccessful\n");
		exit (0);;
	}

	long buff_sz = (PG_SZ * NR_PAGES_READ);
	char *buffer = (char*) malloc(buff_sz * sizeof(char));

	//posix_fadvise(fd, 0, 0, POSIX_FADV_WILLNEED);


	size_t readnow;
	readnow = syscall(449, fd, ((char *)buffer), 
			//PG_SZ*NR_PAGES_READ, 0, 0, NR_PAGES_RA*PG_SZ);
			PG_SZ*NR_PAGES_READ, 0, 0, FILESIZE);

	close(fd);


	return 0;
}

