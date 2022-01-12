#ifndef _UTIL_HPP
#define _UTIL_HPP

#include <atomic>

#define PAGESIZE 4096 //Page size
#define PAGESHIFT 12 //2^12 is 4096 bytes
#define NR_FREE_PAGES 5 //Number of pages to be released at once
#define DEFAULT_TIMES_PREFETCH 10 //prefetch window is x*readsize
#define DEFAULT_FUTURE_PREFETCH 1 //prefetch the very next stride

#define ENV_PREFETCH "TIMESPREFETCH" //How big should be the prefetch window
#define ENV_FUTURE "FUTUREPREFETCH" //How far in the future do I want to prefetch
#define ENV_CACHE_LIMIT "APPCACHELIMIT" //cache limit for the application in Bytes
#define MEMINFO "/proc/meminfo"

#ifdef DEBUG
#define debug_print(...) printf(__VA_ARGS__ )
//#define debug_print(...) fprintf( stderr, __VA_ARGS__ )
#else
#define debug_print(...) do{ }while(0)
#endif

#define gettid() syscall(SYS_gettid)

#endif
