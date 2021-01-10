/*
 * This file takes the decisions on 
 * Prefetching and Demotion/relinquishing of memory
`*/
#include <bits/stdc++.h>

#include "ngram.hpp"

/*
 * Questions to answer
 * 1. How much to remove/prefetch?
 * 2. When to act?
 * 3. What about conflicting advises ?
 * */


int handle_read(int fd, off_t pos, size_t bytes)
{
    //Add this read to the corresponding algorithm
    //check if there is a need to take any actions
}

int handle_write(int fd, off_t pos, size_t bytes)
{
    //Add this read to the corresponding algorithm
    //check if there is a need to take any actions
}


int handle_close(int fd)
{
    //remove the element from read and write data
    //Clear/demote corresponding cache elements from memory
}

int handle_open(int fd)
{
    return true;
}
