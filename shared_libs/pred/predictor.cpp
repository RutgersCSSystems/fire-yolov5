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

#include "ngram.hpp"
#include "util.hpp"
#include "predictor.hpp"
#include "sequential.hpp"

#ifdef NGRAM
ngram readobj; //Obj with all the reads info
ngram writeobj; //Obj with all the write info
#endif

#ifdef SEQUENTIAL
sequential seq_readobj;
sequential seq_writeobj;
#endif

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

#ifdef NGRAM_PREDICT
    //dont know what to do if this rn
    if(!toss_biased_coin()) //Low MemPressure with high prob
    {
        posix_fadvise(fd, 0, 0, POSIX_FADV_WILLNEED);
        std::cout << "prefetching fd: " << fd << std::endl;
    }
#endif
    return true;
}


/* Every User read will call this fn:
 * 1. accounts for access pattern and
 * 2. takes appropriate readahead/DONT NEED action
 */
int handle_read(int fd, off_t pos, size_t bytes) {

    //FIXME: @Shaleen, why is defined as static?
    static struct pos_bytes a;

    if(pos <0 || bytes <=0 || fd <=2) //Santization check
        return false;

    a.fd = fd;
    a.pos = pos;
    a.bytes = bytes;

    debug_print("handle_read: fd:%d, pos:%lu, bytes:%zu\n", 
            fd, pos, bytes);

    //Recognizer insert the access
#ifdef NGRAM
    readobj.insert_to_ngram(a);
#endif

#ifdef SEQUENTIAL
    seq_readobj.insert(a);
#endif

   
#ifdef STATS    
    //FIXME: Why are we not calling this inside a TIMER? This is super-high overhead
    gettimeofday(&start, NULL);
#endif

#ifdef _DELAY_PREFETCH
    /*Check if we need to prefetch or we have read enough and can wait for some time?*/
    if(!prefetch_now((void *)&a)) {
        //printf("Delay prefetch \n");
	return 0;
    }
#endif

    /* Prefetch data for next read*/
#ifdef SEQUENTIAL
    off_t stride;
    if(seq_readobj.is_sequential(fd)){ //Serial access = stride 0
        debug_print("handle_read: sequential\n");
        seq_prefetch(a, SEQ_ACCESS);  //prefetch at program path
    }
    else if((stride = seq_readobj.is_strided(fd))){
        debug_print("handle_read: strided: %lu\n", stride);
        seq_prefetch(a, stride); //prefetch in program path
    }
#endif

#ifdef NGRAM_PREDICT
    std::multimap<float, std::string> next_accesses;
    if(toss_biased_coin()){ //High MemPressure
        /*multimap<float, std::string>*/
        next_accesses = readobj.get_next_n_accesses(10);
        /*std::deque<struct pos_bytes>*/
        auto not_needed = readobj.get_notneeded(next_accesses);

        int bytes_removed = 0, i = 0;
        while(bytes_removed < MAX_REMOVAL_AT_ONCE ||
                i < not_needed.size()){

            bytes_removed += not_needed[i].bytes;
            posix_fadvise(not_needed[i].fd, not_needed[i].pos, 
                    not_needed[i].bytes, POSIX_FADV_DONTNEED);
            i++;
        }
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
 * Right now its just doing NGRAM accounting and prediction
 * which is INCOMPLETE/WRONG - We need to change this
 */
int handle_write(int fd, off_t pos, size_t bytes){
    //Add this read to the corresponding algorithm
    //check if there is a need to take any actions
#ifdef NGRAM
    struct pos_bytes a;
    a.fd = fd;
    a.pos = pos;
    a.bytes = bytes;
    writeobj.insert_to_ngram(a);
#endif

#ifdef NGRAM_PREDICT
    std::multimap<float, std::string> next_accesses;
    if(toss_biased_coin()) //High MemPressure
    {
        /*multimap<float, std::string>*/
        next_accesses = writeobj.get_next_n_accesses(10);
        /*std::deque<struct pos_bytes>*/
        auto not_needed = writeobj.get_notneeded(next_accesses);

        int bytes_removed = 0, i = 0;
        while(bytes_removed < MAX_REMOVAL_AT_ONCE ||
                i < not_needed.size())
        {

            bytes_removed += not_needed[i].bytes;
            posix_fadvise(not_needed[i].fd, not_needed[i].pos, 
                    not_needed[i].bytes, POSIX_FADV_DONTNEED);
            i++;
        }
    }
#endif

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

/*
#ifdef NGRAM
    writeobj.remove_from_ngram(fd);
    readobj.remove_from_ngram(fd);
#endif

#ifdef NGRAM_PREDICT
    posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
#endif

    */
    return true;
}


void print_readahead_time(){

	printf("READAHEAD_TIME:%lf us\n", total_readahead_time);
}

