#include <stdio.h>

#include "thpool.h"

int main()
{
    int num_read_threads = 4;
    threadpool workerpool;
    workerpool = thpool_init(num_read_threads);
}
