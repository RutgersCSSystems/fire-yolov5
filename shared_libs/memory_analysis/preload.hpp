#ifndef _FRONTEND_HPP
#define _FRONTEND_HPP

#include <atomic>

#define gettid() syscall(SYS_gettid)

#ifdef DEBUG
#define debug_print(...) printf(__VA_ARGS__ )
//#define debug_print(...) fprintf( stderr, __VA_ARGS__ )
#else
#define debug_print(...) do{ }while(0)
#endif


#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

/* This struct keeps all the data 
 * to be shared across all the 
 * processes and threads of the app
 */
struct shared_dat{
        char a; //just there. no use
        std::atomic<int> first_tid;
};


struct thread_args{
        size_t nr_anon;
        size_t nr_cache;
};


#endif
