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
thread_local sequential seq_readobj;
thread_local sequential seq_writeobj;
#endif
thread_local struct pos_bytes acc;

/* 
 * Keeps track of all filenames wrt its corresponding fd
 * FIXME: Doesnt work for now
 */
thread_local std::unordered_map<int, std::string> fd_to_filename;


/*Time Spent in prefetching*/
thread_local struct timeval stop, start;
thread_local double total_readahead_time = 0.0; //Time in microseconds

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

    //printf("handle_open: fd:%d %s\n", fd, filename);

#if 0 //def SEQUENTIAL
	seq_readobj.init_seq_likelyness(fd);
#endif
    return true;
}


/* Every User read will call this fn:
 * 1. accounts for access pattern and
 * 2. takes appropriate readahead/DONT NEED action
 */
int g_num_prefetches = 0;

size_t handle_read(int fd, off_t pos, size_t bytes) {
    if(pos <0 || bytes <=0 || fd <=2) //Santization check
        return false;

    long stride;
    off_t prefetch_fd_pos = 0;
    size_t prefetch_size = 0;

    acc.fd = fd;
    acc.bytes = bytes;
#ifndef READ_RA 
    /*
     * handle_read implementation assumes that
     * pread/fread/read syscall was called before 
     * meaning pos is one after the read
     * since read_ra would be done after handle_read
     * simple hack to keep correctness
     */
    acc.pos = pos;
#else
    acc.pos = pos + bytes;
#endif


#ifdef SEQUENTIAL
    seq_readobj.insert(acc);
#endif

#ifdef STATS 
    //FIXME: Why are we not calling this inside a TIMER? This is super-high overhead
    gettimeofday(&start, NULL);
#endif

    /* Prefetch data for next read*/
#ifdef SEQUENTIAL

#ifdef _DELAY_PREFETCH //should only happen if SEQUENTIAL is enabled
    if(!seq_readobj.prefetch_now_fd((void *)&acc, fd)) {
        //printf("Delay prefetch %d\n", g_num_prefetches);
	return 0;
    }
#endif

    if((stride = seq_readobj.is_strided(fd))){
        //printf("handle_read: strided: %ld\n", stride);
        prefetch_size = seq_prefetch(acc, stride); //prefetch in program path
	g_num_prefetches++;
    }

    if(prefetch_size) {	   
	prefetch_fd_pos = acc.pos + prefetch_size;    
	debug_print("handle_read: fd: %d, acc.pos %lu strided: %lu prefetch_size %lu\n", 
			fd, acc.pos, prefetch_fd_pos, prefetch_size);
    	seq_readobj.insert_prefetch_pos(fd, prefetch_fd_pos);
    }

#endif

#ifdef STATS
    gettimeofday(&stop, NULL);
    total_readahead_time += (stop.tv_sec - start.tv_sec) * 1000000 + (stop.tv_usec - start.tv_usec);
#endif
    return prefetch_size;
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

