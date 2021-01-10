/*
 * This file takes the decisions on 
 * Prefetching and Demotion/relinquishing of memory
 `*/
#include <bits/stdc++.h>

#include "ngram.hpp"
#include "util.hpp"

#ifdef NGRAM
ngram readobj; //Obj with all the reads info
ngram writeobj; //Obj with all the write info
#endif

/*
 * Questions to answer
 * 1. How much to remove/prefetch?
 * 2. When to act? - How frequently ?
 * 3. What about conflicting advises ?
 * 4. What advice is not taken by the kernel ?
 * */


int handle_read(int fd, off_t pos, size_t bytes)
{
    //check if there is a need to take any actions
    //Add this read to the corresponding algorithm
#ifdef NGRAM
    struct pos_bytes a;
    a.fd = fd;
    a.pos = pos;
    a.bytes = bytes;
    readobj.insert_to_ngram(a);
#endif

    return true;
}

int handle_write(int fd, off_t pos, size_t bytes)
{
    //Add this read to the corresponding algorithm
    //check if there is a need to take any actions
#ifdef NGRAM
    struct pos_bytes a;
    a.fd = fd;
    a.pos = pos;
    a.bytes = bytes;
    writeobj.insert_to_ngram(a);
#endif

    return true;
}


int handle_close(int fd)
{

    //remove the element from read and write data
#ifdef NGRAM
    writeobj.remove_from_ngram(fd);
    readobj.remove_from_ngram(fd);
#endif
    
    //Clear/demote corresponding cache elements from memory
    return true;
}

int handle_open(int fd)
{
    //dont know what to do if this rn
    return true;
}
