//#define _POSIX_C_SOURCE 200809L
#define _GNU_SOURCE
#include <errno.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
//#include <numa.h>
#include <time.h>
#include <inttypes.h>
#include <pthread.h>
#include <signal.h>
#include <string.h>

#define __NR_start_trace 333

#define CLEAR_COUNT     0
#define COLLECT_TRACE 1
#define PRINT_STATS 2
#define PFN_TRACE 4
#define PFN_STAT 5
#define TIME_TRACE 6
#define TIME_STATS 7
#define TIME_RESET 8
#define COLLECT_ALLOCATE 9
#define PRINT_ALLOCATE 10

static int setinit;

void sig_handler(int);



static void con() __attribute__((constructor)); 
static void dest() __attribute__((destructor));

void dest() {
    int a = 0;
    fprintf(stderr, "application termination...\n");

//    a = syscall(__NR_start_trace, PRINT_STATS);
//    a = syscall(__NR_start_trace, CLEAR_COUNT);
//	a = syscall(__NR_start_trace, PFN_STAT);

//	a = syscall(__NR_start_trace, TIME_STATS);
//	a = syscall(__NR_start_trace, TIME_RESET);

	a = syscall(__NR_start_trace, PRINT_ALLOCATE);
	a = syscall(__NR_start_trace, CLEAR_COUNT);
    //sleep(5);
}

void con() {
  
    if(!setinit) {
        fprintf(stderr, "initiating tracing...\n");

//      long int a = syscall(__NR_start_trace, COLLECT_TRACE);
//		long int b = syscall(__NR_start_trace, PFN_TRACE);
//        long int a = syscall(__NR_start_trace, COLLECT_TRACE);
//		long int b = syscall(__NR_start_trace, PFN_TRACE);
//		long int a = syscall(__NR_start_trace, TIME_TRACE);
		long int a = syscall(__NR_start_trace, COLLECT_ALLOCATE);

        //Register KILL
        struct sigaction action;
        memset(&action, 0, sizeof(struct sigaction));
        action.sa_handler = sig_handler;
        sigaction(SIGKILL, &action, NULL);
        setinit = 1;
     }  	
}

void sig_handler(int sig) {
  
    switch (sig) {
        case SIGKILL:
            dest();
        default:
	    return;
    }
}
/*******************************************/
