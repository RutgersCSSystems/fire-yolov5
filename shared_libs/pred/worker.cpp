#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

#include <sys/wait.h>
#include <sys/types.h>

#include "worker.hpp"

static void Handler(int Sig, siginfo_t *Info, void *context)
{
    pid_t sender_pid = Info->si_pid;

    if(Sig == PREFETCH_SIG) //Want to Run
    {
        //Prefetch code
    }
    if(Sig == RELINQUISH_SIG)
    {
        //Relinquish code
    }
}

void Signalhandle()
{
    struct sigaction SigAction;
    SigAction.sa_sigaction = Handler;
    SigAction.sa_flags |= SA_SIGINFO;

    sigaddset(&SigAction.sa_mask, PREFETCH_SIG);
    sigaddset(&SigAction.sa_mask, RELINQUISH_SIG);

    if(sigaction(PREFETCH_SIG, &SigAction, NULL) != 0)
    {
        printf("\nThere is a problem with SIGUSR1\n");
        exit(1);
    }

    if(sigaction(RELINQUISH_SIG, &SigAction, NULL) != 0)
    {
        printf("\nThere is a problem with SIGUSR2\n");
        exit(1);
    }
}

void *bg_worker(void *ptr)
{
    //Call this function from worker pthread
    printf("hloo \n");    
    return NULL;
}

void thread_fn(void)
{
    pthread_t bg_thread;
    cpu_set_t cpuset;
    int last_cpu_id= sysconf(_SC_NPROCESSORS_ONLN) -1;
    CPU_ZERO(&cpuset);
    CPU_SET(last_cpu_id, &cpuset);

    //TODO: add FUnction mame
    if(pthread_create(&bg_thread, NULL, bg_worker, NULL))
    {
        fprintf(stderr, "Error creating thread\n");
        exit(-1);
    }
    if(pthread_getaffinity_np(bg_thread, 
                sizeof(cpu_set_t), &cpuset) != 0)
    {
        fprintf(stderr, "Error setting thread affinity\n");
        exit(-1);
    }

}
