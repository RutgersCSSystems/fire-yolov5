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

#define __NR_start_trace 333

void sig_handler(int);


static void con() __attribute__((constructor)); 

void con() {
    fprintf(stderr, "initiating tracing...\n");
    long int a = syscall(__NR_start_trace, 1);
     //Register sigterm
     signal(SIGTERM, sig_handler);
}

void sig_handler(int sig) {
  
    long int a = 0;
 
    switch (sig) {
        case SIGTERM:
            fprintf(stderr, "application termination...\n");
            a = syscall(__NR_start_trace, 2);
            a = syscall(__NR_start_trace, 0);            
        default:
	    return;
    }
}
/*******************************************/
