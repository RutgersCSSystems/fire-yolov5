#ifndef _UTIL_HPP
#define _UTIL_HPP

#define PAGESIZE 4096 //Page size
#define PAGESHIFT 12 //2^12 is 4096 bytes
#define NR_FREE_PAGES 5 //Number of pages to be released at once
#define DEFAULT_TIMES_PREFETCH 1 //prefetch window is x*readsize

#define ENV_PREFETCH "TIMESPREFETCH"


#define MEMINFO "/proc/meminfo"

#ifdef DEBUG
#define debug_print(...) printf(__VA_ARGS__ )
//#define debug_print(...) fprintf( stderr, __VA_ARGS__ )
#else
#define debug_print(...) do{ }while(0)
#endif

struct pos_bytes{
	int fd; //file descriptor
	off_t pos; //File seek position
	size_t bytes; //size of read/write
};

/*Returns P(true) = MemPressure*/
bool toss_biased_coin();

#endif
