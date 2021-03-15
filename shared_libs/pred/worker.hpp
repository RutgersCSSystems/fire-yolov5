#ifndef _WORKER_HPP
#define _WORKER_HPP

#include "util.hpp"

#define PREFETCH_SIG SIGUSR1
#define RELINQUISH_SIG SIGUSR2
#define PREFETCH "prefetch"
#define RELINQUISH "relinq"
#define DURATION 1

struct msg{
	struct pos_bytes pos;
	off_t stride;
	char instr[10]; //instruction
};

void thread_fn(void);
void clean_state();
bool instruct_prefetch(struct pos_bytes pos, off_t stride);

#endif
