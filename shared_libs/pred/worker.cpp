#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <pthread.h>
#include <fcntl.h>
#include <errno.h>
#include <semaphore.h>
#include <string.h>

#include <iostream>

#include <sys/wait.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

#include "sequential.hpp"
#include "worker.hpp"

#define WORKERQ "/tmp/passmessages"
#define SEMAPHORE "just_one_bg_thread"

sem_t   *mysemp;
const char semname[] = "mysem";
int fifofd = -1;


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


/* Registering the signal handler*/
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
    struct msg message;
    while(1){
        if(!fifofd)
            continue;
        while(read(fifofd, &message, sizeof(struct msg)) <= 0){
            strcpy(message.instr, "");
        }

        /*Prefetch*/
        if(strcmp(message.instr, PREFETCH) == 0){
            if(__seq_prefetch(message.pos, message.stride) != true){
                printf("ERROR: %s: unable to prefetch\n", __func__);
            }
        }
        else if(strcmp(message.instr, RELINQUISH) == 0){
            debug_print("recvd RELINQUISH_SIG\n");
        }
    }
}


/*creates and tries to get the semaphore*/
bool get_semaphore(){

    mysemp = sem_open(semname, O_CREAT, 0666, 1);
    if (mysemp == SEM_FAILED) {
        printf("sem_open() failed %s\n", strerror(errno));
    }

    struct timespec abs_time;
    abs_time.tv_sec = 1;
    abs_time.tv_nsec = 0;

    int sts = sem_timedwait(mysemp, &abs_time);
    if (sts == 0) // got the lock
    {
        debug_print("%s: got semaphore : %d\n", __func__, getpid());
        return true;
    }
    else if (errno == ETIMEDOUT)
        return false;
}


/* This function spawns the worker thread
*/
void thread_fn(void){
    pthread_t bg_thread;
    cpu_set_t cpuset;

#ifdef __NO_BG_THREADS
    return;
#else
    //if this proc is successful in generating FIFO
    //generate the pthread and populate such 
    if(get_semaphore())
    {
        //create fifo
        if(mkfifo(WORKERQ, 0666) != 0){
            printf("ERROR: mkfifo : %s\n", strerror(errno));
            exit(-1);
        }
        //create pthread

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
    }
    /*open fifo*/
    if((fifofd = open(WORKERQ, O_RDWR | O_SYNC | O_CREAT, 0666)) == -1){
        printf("ERROR: unable to open fifo: %s\n", strerror(errno));
        exit(-1);
    }

#endif
}


/*send message to prefetch */
bool instruct_prefetch(struct pos_bytes pos, off_t stride){
    if(stride < 0)
        return false; 

    struct msg message;

    message.pos = pos;
    message.stride = stride;
    strcpy(message.instr, PREFETCH);

    if(fifofd)
        return write(fifofd, &message, sizeof(struct msg));

    return false;
}


/*Cleans all state at destruction*/
void clean_state(){
    sem_close(mysemp);
    sem_unlink(semname);

    close(fifofd);
    unlink(WORKERQ);
}
