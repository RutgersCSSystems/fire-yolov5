#ifndef _WORKER_HPP
#define _WORKER_HPP

#include "util.hpp"

#define PREFETCH_SIG SIGUSR1
#define RELINQUISH_SIG SIGUSR2
#define DURATION 1

struct msg{
	struct pos_bytes pos;
	off_t stride;
	char msg[10];
};

void thread_fn(void);
void destroy_semaphore();

#endif
