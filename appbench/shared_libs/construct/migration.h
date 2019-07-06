#ifndef MMAPLIB_H_
#define MMAPLIB_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <assert.h>
#include <time.h>

#define __NR_start_trace 333

#ifdef __cplusplus
extern "C" {
#endif
int record_addr(void* addr, size_t size);
void migrate_pages(int node);
int migrate_now();
void init_allocs();
void stopmigrate();

#define HETERO_MIGRATE_FREQ 17
#define FREQ 10000
#define HETERO_OBJ_AFF 18
#define HETERO_DISABLE_MIGRATE 19
#define HETERO_MIGRATE_LISTCNT 20

#define MIGRATE_LIST_CNT 100


void set_migration_freq() {
#ifdef _MIGRATE
    syscall(__NR_start_trace, HETERO_MIGRATE_FREQ, FREQ);
#else
    syscall(__NR_start_trace, HETERO_MIGRATE_FREQ, 9000000000);
#endif
}


void set_migrate_list_cnt() {            
#ifdef _MIGRATE
	syscall(__NR_start_trace, HETERO_MIGRATE_LISTCNT, MIGRATE_LIST_CNT);
#else
	syscall(__NR_start_trace, HETERO_MIGRATE_LISTCNT, 9000000000);
#endif
}


void enable_object_affn() {
#ifdef _OBJAFF
    syscall(__NR_start_trace, HETERO_OBJ_AFF, HETERO_OBJ_AFF);
#endif
}

void disable_migration() {
#ifdef _DISABLE_MIGRATE
    syscall(__NR_start_trace, HETERO_DISABLE_MIGRATE, HETERO_DISABLE_MIGRATE);
#endif
}


#ifdef __cplusplus
}
#endif

#endif
