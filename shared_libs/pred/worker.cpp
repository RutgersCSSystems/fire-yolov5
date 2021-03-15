#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <pthread.h>

#include <iostream>

#include <sys/wait.h>
#include <sys/types.h>

#include "sequential.hpp"
#include "worker.hpp"

#define __NO_BG_THREADS //this Makes things go synchronously

/*
 * This function will actually do the work at signal recv
 */
static void handler(int sig, siginfo_t *info, void *context){
    pid_t sender_pid = info->si_pid;

    if(sig == PREFETCH_SIG){ //Want to Run
        //Prefetch code
#ifdef DEBUG
        std::cout << "worker thread prefetch" << std::endl;
#endif
        //read the list
        //perform readhead
        //just do it for one thread and get the access pattern
    } else if(sig == RELINQUISH_SIG){
        //Relinquish code
#ifdef DEBUG
        std::cout << "worker thread relinquish" << std::endl;
#endif
    }
    return;
}


/* Registering the signal handler
 */
void signal_handle(){
    struct sigaction sig_action;
    sig_action.sa_sigaction = handler;
    sig_action.sa_flags |= SA_SIGINFO;

    sigaddset(&sig_action.sa_mask, PREFETCH_SIG);
    sigaddset(&sig_action.sa_mask, RELINQUISH_SIG);

    if(sigaction(PREFETCH_SIG, &sig_action, NULL) != 0){
        fprintf(stderr,"\nThere is a problem with SIGUSR1\n");
        exit(-1);
    }

    if(sigaction(RELINQUISH_SIG, &sig_action, NULL) != 0){
        fprintf(stderr, "\nThere is a problem with SIGUSR2\n");
        exit(-1);
    }
}

/*
 * The worker while waiting for signal from others
 */
void *bg_worker(void *ptr){
#ifdef __NO_BG_THREADS
    
#else
    signal_handle();

    while(1){
        sleep(DURATION);
    }
#endif
    return NULL;
}


/* This function spawns the worker thread
 */
void thread_fn(void){
    pthread_t bg_thread;
    cpu_set_t cpuset;

#ifdef __NO_BG_THREADS
    bg_worker(NULL);
#else

    int last_cpu_id= sysconf(_SC_NPROCESSORS_ONLN) -1;
    CPU_ZERO(&cpuset);
    CPU_SET(last_cpu_id, &cpuset);

    if(pthread_create(&bg_thread, NULL, bg_worker, NULL)){
        fprintf(stderr, "Error creating thread\n");
        exit(-1);
    }
    if(pthread_getaffinity_np(bg_thread, 
                sizeof(cpu_set_t), &cpuset) != 0){
        fprintf(stderr, "Error setting thread affinity\n");
        exit(-1);
    }
#endif
}
