#ifndef _UTIL_HPP
#define _UTIL_HPP

#define PAGESIZE 4096 //Page size
#define __PREAD_RA_SYSCALL 449

#define likely(x)      __builtin_expect(!!(x), 1)
#define unlikely(x)    __builtin_expect(!!(x), 0)

#ifdef DEBUG
#define debug_print(...) printf(__VA_ARGS__ )
//#define debug_print(...) fprintf( stderr, __VA_ARGS__ )
#else
#define debug_print(...) do{ }while(0)
#endif

#define gettid() syscall(SYS_gettid)

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
	size_t ra_count;

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

};

struct thread_args{
    int fd; //opened file fd
    long offset; //where to start
    long file_size; //total filesize
    long prefetch_size; //size of each prefetch req
};

#endif
