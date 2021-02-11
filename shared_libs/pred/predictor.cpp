/*
 * This file takes the decisions on 
 * Prefetching and Demotion/relinquishing of memory
 `*/
#include <bits/stdc++.h>
#include <unistd.h>
#include <fcntl.h>

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

/*
 * Questions to answer
 * 1. How much to remove/prefetch?
 * 2. When to act? - How frequently ?
 * 3. What about conflicting advises ?
 * 4. What advice is not taken by the kernel ?
 * */

/* Every User read will call this fn:
 * 1. accounts for access pattern and
 * 2. takes appropriate readahead/DONT NEED action
 */
int handle_read(int fd, off_t pos, size_t bytes){

    if(pos <0 || bytes <0) //Santization check
        return false;

    static struct pos_bytes a;
    a.fd = fd;
    a.pos = pos;
    a.bytes = bytes;

    //Recognizer insert the access
#ifdef NGRAM
    readobj.insert_to_ngram(a);
#endif

#ifdef SEQUENTIAL
    seq_readobj.insert(a);
#endif

#ifdef SEQUENTIAL
    off_t stride;
    if(seq_readobj.is_sequential(fd)){ //Serial access = stride 0
       seq_prefetch(a, SEQ_ACCESS);  //prefetch at program path
    }
    else if((stride = seq_readobj.is_strided(fd))){
#ifdef DEBUG
	printf("handle_read: strided: %lu\n", stride);
#endif
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
 * Called at each close operation from the user
 * Remove entries from all accounting methods
 */
int handle_close(int fd){
    //remove the element from read and write data
    return true; //dont do anything right now
#ifdef NGRAM
    writeobj.remove_from_ngram(fd);
    readobj.remove_from_ngram(fd);
#endif

#ifdef SEQUENTIAL
    seq_readobj.remove(fd);
    seq_writeobj.remove(fd);
#endif

#ifdef NGRAM_PREDICT
    posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
#endif

    //Clear/demote corresponding cache elements from memory
    return true;
}


/* Called at each open operation from the user
 * This function doesnt have a specific function right now
 */
int handle_open(int fd){
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
