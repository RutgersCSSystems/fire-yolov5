#ifndef _WORKER_HPP
#define _WORKER_HPP

#include "util.hpp"

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
bool instruct_prefetch(void *work);
void clean_state();

#endif
