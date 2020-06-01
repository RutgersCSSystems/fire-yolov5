#define _GNU_SOURCE
#include <errno.h>
#include <sys/mman.h>
#include <sys/syscall.h>
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
#include <unistd.h>
#include <stdbool.h>


static void con() __attribute__((constructor));
static void des() __attribute__((destructor));

bool printed = false;
pthread_t thread_id;
int mpiRank = -1;
unsigned long ReclaimedPages = 0;

/*
   void *myThreadFun(void *vargp)
   {
   unsigned long NumPages; 
   int RecTime;
   const char* NumP = getenv("RECNUMPAGES");
   const char* RTime = getenv("RECTIME");
   if(NumP==NULL || RTime==NULL)
   {
   printf("RECNUMPAGES or RECTIME is not defined !!\n");
   return NULL;
   }
   NumPages = atol(NumP);
   RecTime = atoi(RTime);

//printf("LD_PRELOAD rank = %d\n", mpiRank);
for(;;)
{
ReclaimedPages += syscall(333, (unsigned long)NumPages);
sleep(RecTime);
}
return NULL;
}
*/

int reportrank_(int *rank)
{
	//    printf("Preload rank = %d", *rank);
	//mpiRank = *rank;
	//if(mpiRank == 0)
	{
		unsigned long rc = syscall(333, (unsigned long) 0); //SetTaskStruct
		//pthread_create(&thread_id, NULL, myThreadFun, NULL);
	}
	return 0;
}

/*
   void con()
   {
   printf("Before Thread\n");

//const char* s = getenv("HELLO");
//printf("%s\n", s);
//pthread_create(&thread_id, NULL, myThreadFun, NULL);

printf("After Thread\n");
}
*/

int getrec_pages_(int *rank)
{
	//mpiRank = *rank;
	//pthread_cancel(thread_id);
	ReclaimedPages += syscall(333, (unsigned long) 1); //GetNumberofwritten
	return 1;
}

void des()
{
	if(printed == false)
	{
		//pthread_cancel(thread_id);
		//ReclaimedPages = syscall(333, (unsigned long) 1); //GetNumberofwritten
		printf("Destructor %lu\n", ReclaimedPages);
		printed = true;
	}
}
