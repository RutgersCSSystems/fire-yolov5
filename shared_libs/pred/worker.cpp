#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>


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
