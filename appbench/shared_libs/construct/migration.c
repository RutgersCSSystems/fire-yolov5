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
#include "migration.h"

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

#define HETERO_PGCACHE 11
#define HETERO_BUFFER 12
#define HETERO_JOURNAL 13
#define HETERO_RADIX 14
#define HETERO_FULLKERN 15
#define HETERO_SET_FASTMEM_NODE 16

#ifndef _SLOWONLY
#define HETERO_FASTMEM_NODE 0
#else
#define HETERO_FASTMEM_NODE 1
#endif



static int setinit;

void sig_handler(int);



static void con() __attribute__((constructor)); 
static void dest() __attribute__((destructor));



void dest() {
    fprintf(stderr, "application termination...\n");

    /*a = syscall(__NR_start_trace, PRINT_STATS);
    a = syscall(__NR_start_trace, CLEAR_COUNT);
    a = syscall(__NR_start_trace, PFN_STAT);
    a = syscall(__NR_start_trace, TIME_STATS);
    a = syscall(__NR_start_trace, TIME_RESET);*/
    syscall(__NR_start_trace, PRINT_ALLOCATE, 0);
    syscall(__NR_start_trace, CLEAR_COUNT, 0);
}

void con() {
  
    struct sigaction action;
    pid_t pid = getpid();

    /* Do not enable hetero if HETERO disabled */
#ifndef _DISABLE_HETERO
    if(!setinit) {
        fprintf(stderr, "initiating tracing...\n");
        /*a = syscall(__NR_start_trace, COLLECT_TRACE);
        a = syscall(__NR_start_trace, PFN_TRACE);
        a = syscall(__NR_start_trace, COLLECT_TRACE);
        a = syscall(__NR_start_trace, PFN_TRACE);
        a = syscall(__NR_start_trace, TIME_TRACE);*/
        syscall(__NR_start_trace, COLLECT_ALLOCATE, 0);
        syscall(__NR_start_trace, HETERO_PGCACHE, 0);
        syscall(__NR_start_trace, HETERO_BUFFER, 0);
        syscall(__NR_start_trace, HETERO_JOURNAL, 0);
        syscall(__NR_start_trace, HETERO_RADIX, 0);
        syscall(__NR_start_trace, HETERO_FULLKERN, 0);
        syscall(__NR_start_trace, HETERO_SET_FASTMEM_NODE, HETERO_FASTMEM_NODE);
	syscall(__NR_start_trace, (int)pid);
	syscall(__NR_start_trace, HETERO_SET_FASTMEM_NODE, HETERO_FASTMEM_NODE);

	set_migration_freq();
	enable_object_affn();
	disable_migration();
	set_migrate_list_cnt();

        //Register KILL
        memset(&action, 0, sizeof(struct sigaction));
        action.sa_handler = sig_handler;
        sigaction(SIGKILL, &action, NULL);
        //setinit = 1;
     } 
#endif
 	
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
