#define _LARGEFILE64_SOURCE
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/syscall.h>
#include <sys/time.h>

#define __NR_start_crosslayer 448

#define NR_PAGES_READ 10
#define NR_PAGES_RA 20
#define PG_SZ 4096

#define ENABLE_FILE_STATS 1
#define DISABLE_FILE_STATS 2
#define RESET_GLOBAL_STATS 3
#define PRINT_GLOBAL_STATS 4

void set_crosslayer(){
	syscall(__NR_start_crosslayer, ENABLE_FILE_STATS, 0);
}

void reset_global_stats(){
	syscall(__NR_start_crosslayer, RESET_GLOBAL_STATS, 0);
}

void print_global_stats(){
	syscall(__NR_start_crosslayer, PRINT_GLOBAL_STATS, 0);
}

int main() {

	//set_crosslayer();
	//reset_global_stats();

	int fd;

	long nr_read = 0; //controls the readaheads

	long size = (10L * 1024L * 1024L * 1024L); //10GB

	long buff_sz = (PG_SZ * NR_PAGES_READ);

	char *buffer = (char*) malloc(buff_sz * sizeof(char));
	fd = open("bigfakefile.txt", O_RDWR);
	if (fd == -1){
		printf("\nFile Open Unsuccessful\n");
		exit (0);;
	}

#ifdef ONLYAPP
	//Disable OS pred
	posix_fadvise(fd, 0, 0, POSIX_FADV_RANDOM);
#endif

	off_t chunk = 0;
	lseek64(fd, 0, SEEK_SET);

	while ( chunk < size ){
		size_t readnow;
#ifdef ONLYOS //No PRediction from app
		readnow = pread(fd, ((char *)buffer), PG_SZ*NR_PAGES_READ, chunk);
#elif READRA //Read+Ra from App
		if(nr_read >= NR_PAGES_RA){
			readnow = syscall(449, fd, ((char *)buffer), 
					PG_SZ*NR_PAGES_READ, chunk, 0, NR_PAGES_RA*PG_SZ);
			nr_read = 0;
		}
		else
		{
			readnow = syscall(449, fd, ((char *)buffer), 
					PG_SZ*NR_PAGES_READ, chunk, 0, 0);
		}
		nr_read += NR_PAGES_READ;
#elif APP_NATIVE_RA //Read and Readahead from App
		readnow = pread(fd, ((char *)buffer), PG_SZ*NR_PAGES_READ, chunk);
#endif

		if (readnow < 0 ){
			printf("\nRead Unsuccessful\n");
			free (buffer);
			close (fd);
			return 0;
		}
		chunk += readnow; //offset
		nr_read += NR_PAGES_READ;
#ifdef APP_NATIVE_RA
		if(nr_read >= NR_PAGES_RA){
			readahead(fd, chunk, PG_SZ*NR_PAGES_RA);
		}
#endif
	}

	printf("Read done\n");

	close(fd);
	//print_global_stats();
	return 0;
}
