#include <iostream>
#define PREFETCH_SIG SIGUSR1
#define RELINQUISH_SIG SIGUSR2
#define DURATION 1

void thread_fn(void);

