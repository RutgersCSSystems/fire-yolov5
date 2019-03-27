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
#define FREQ 5000
void set_migration_freq() {
    syscall(__NR_start_trace, HETERO_MIGRATE_FREQ, FREQ);
}


#ifdef __cplusplus
}
#endif

#endif
