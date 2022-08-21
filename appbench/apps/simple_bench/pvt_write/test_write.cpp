#define _LARGEFILE64_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <sys/sysinfo.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <sys/resource.h>

#define FILENAME "testfile.txt"
#define PAGESIZE 4096


#ifndef NR_PAGES
#define NR_PAGES 10
#endif


#define __READAHEAD_INFO 451

/*
 * pread_ra read_ra_req struct
 * this struct is used to send and receive info from kernel about
 * the current readahead with the typical read
 */
struct read_ra_req{

	/*These are to be filled while sending the pread_ra req
	 * position for readahead and nr_bytes for readahead
	 */
	loff_t ra_pos;
	size_t ra_count; //in bytes

	/* these are values returned by the OS
	 * for the above given readahead request
	 * 1. how many pages were already present
	 * 2. For how many pages, bio was submitted
	 */
	unsigned long nr_present;
	unsigned long bio_req_nr;

	/* this is used to return the number of cache usage in bytes
	 * used by this application.
	 * enable CONFIG_CACHE_LIMITING(linux) and ENABLE_CACHE_LIMITING(library)
	 * to get a non-zero value
	 */
	long total_cache_usage; //total cache usage in bytes (OS return)
	bool full_file_ra; //populated by app true if pread_ra is being done to get full file
	long cache_limit; //populated by the app, desired cache_limit

	unsigned long nr_free; //nr pages that are free in mem


	/*
	 * The following are populated by the kernel
	 * and returned to user space
	 */
	unsigned long *data;  //page bitmap for readahead file
	unsigned long nr_relevant_ulongs; //number of bits relevant for the file


};

long readahead_info(int fd, loff_t offset, size_t count, struct read_ra_req *ra_req)
{
        return syscall(__READAHEAD_INFO, fd, offset, count, ra_req);
}

int main(){
        int fd;
        char *buffer = (char*)malloc(sizeof(PAGESIZE));
        fd = open(FILENAME, O_CREAT | O_RDWR, S_IWUSR | S_IRUSR | S_IXUSR);

	struct read_ra_req ra;


	ra.data = NULL;
	readahead_info(fd, 0, 0, &ra);


	ra.data = (unsigned long *) malloc(sizeof(unsigned long) * 10);

        for(int i=0; i<PAGESIZE; i++){
                buffer[i] = 'c';
        }


        for(int i=0; i<NR_PAGES; i++){
                pwrite(fd, buffer, PAGESIZE, i*PAGESIZE);

		if(readahead_info(fd, 0, PAGESIZE, &ra) < 0)
		{
			printf("readahead_info: failed\n");
			goto exit;
		}
		printf("%lu\n", ra.data[0]);
        }

exit:
        return 0;
}
