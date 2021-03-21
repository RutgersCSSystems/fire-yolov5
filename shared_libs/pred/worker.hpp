#ifndef _WORKER_HPP
#define _WORKER_HPP

#include "util.hpp"
#include "utils/thpool.h"

#define PREFETCH_SIG SIGUSR1
#define RELINQUISH_SIG SIGUSR2
#define PREFETCH "prefetch"
#define RELINQUISH "relinq"
#define DURATION 1


/*used to add work to queue*/
struct msg{
	struct pos_bytes pos;
	off_t stride;
};

void thread_fn(int nr_workers);
threadpool get_thpool();
void clean_state();

#endif
