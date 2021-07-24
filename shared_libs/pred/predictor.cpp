/*
 * This file takes the decisions on 
 * Prefetching and Demotion/relinquishing of memory
 `*/
#include <bits/stdc++.h>
#include <string>
#include <iostream>
#include <unistd.h>
#include <fcntl.h>
#include <sys/time.h>

#include "util.hpp"
#include "predictor.hpp"
#include "sequential.hpp"

#ifdef SEQUENTIAL
sequential seq_readobj;
sequential seq_writeobj;
#endif
struct pos_bytes acc;

/* Keeps track of all filenames wrt its corresponding fd*/
std::unordered_map<int, std::string> fd_to_filename;


/*Time Spent in prefetching*/
struct timeval stop, start;
double total_readahead_time = 0.0; //Time in microseconds

/*
 * Questions to answer
 * 1. How much to remove/prefetch?
 * 2. When to act? - How frequently ?
 * 3. What about conflicting advises ?
 * 4. What advice is not taken by the kernel ?
 * */


/* Called at each open operation from the user
 * populates fd_to_filename hashmap
 */
bool handle_open(int fd, const char *filename){

    if(fd<=2 || filename == NULL)
        return false;

    debug_print("handle_open: fd:%d %s\n", fd, filename);

    /* REMOVED DUE TO UNINTERPRETABLE ERROR: FIXME
    std::string str(filename);
    fd_to_filename[fd] = filename;
    */

    /*
    if(fd_to_filename.find(fd) == fd_to_filename.end() ||
            fd_to_filename[fd] == str)
        fd_to_filename[fd] = str;
    else{
        debug_print("%s: fd:%d associated with new file: %s\n", 
                __func__, fd, filename);
        fd_to_filename[fd] = str;
        return false;
    }
    */

    return true;
}


/* Every User read will call this fn:
 * 1. accounts for access pattern and
 * 2. takes appropriate readahead/DONT NEED action
 */
int handle_read(int fd, off_t pos, size_t bytes) {
    if(pos <0 || bytes <=0 || fd <=2) //Santization check
        return false;

    acc.fd = fd;
    acc.pos = pos;
    acc.bytes = bytes;

    debug_print("handle_read: fd:%d, pos:%lu, bytes:%zu\n", 
            fd, pos, bytes);

#ifdef SEQUENTIAL
    seq_readobj.insert(acc);
#endif

   
#ifdef STATS 
    //FIXME: Why are we not calling this inside a TIMER? This is super-high overhead
    gettimeofday(&start, NULL);
#endif

#ifdef _DELAY_PREFETCH
    /*Check if we need to prefetch or we have read enough and can wait for some time?*/
    if(!prefetch_now((void *)&acc)) {
        //printf("Delay prefetch \n");
	return 0;
    }
#endif

    /* Prefetch data for next read*/
#ifdef SEQUENTIAL
    off_t stride;
    if(seq_readobj.is_sequential(fd)){ //Serial access = stride 0
        debug_print("handle_read: sequential\n");
        seq_prefetch(acc, SEQ_ACCESS);  //prefetch at program path
    }
    else if((stride = seq_readobj.is_strided(fd))){
        debug_print("handle_read: strided: %lu\n", stride);
        seq_prefetch(acc, stride); //prefetch in program path
    }
#endif

#ifdef STATS
    gettimeofday(&stop, NULL);
    total_readahead_time += (stop.tv_sec - start.tv_sec) * 1000000 + (stop.tv_usec - start.tv_usec);
#endif

    return true;
}


/* TO be called at each write by the user 
 * Functionality of this function is still TBD
 */
int handle_write(int fd, off_t pos, size_t bytes){
    //Add this read to the corresponding algorithm
    //check if there is a need to take any actions
    return true;
}


/*
 * FIXME: Called at each close operation from the user
 * Remove entries from all accounting methods
 */
int handle_close(int fd){

    /*FIXME: erase function is giving signal 8*/
    //fd_to_filename.erase(fd);

#ifdef SEQUENTIAL
    seq_readobj.remove(fd);
    seq_writeobj.remove(fd);
#endif

    return true;
}


void print_readahead_time(){

	printf("READAHEAD_TIME:%lf us\n", total_readahead_time);
}

