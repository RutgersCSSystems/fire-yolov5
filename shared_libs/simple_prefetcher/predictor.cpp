#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <dlfcn.h>
#include <unistd.h>
#include <fcntl.h>
#include <limits.h>
#include <sched.h>
#include <stdarg.h>
#include <errno.h>
#include <time.h>

#include <iostream>
#include <cstdlib>
#include <ctime>
#include <fstream>
#include <algorithm>
#include <map>
#include <deque>
#include <unordered_map>
#include <string>
#include <iterator>
#include <atomic>

#include <sys/sysinfo.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <sys/resource.h>

#ifdef PREDICTOR
#include "predictor.hpp"

void hello_predictor(){
        printf("hello predictor\n");
        return;
}


file_predictor::file_predictor(int this_fd, size_t size){

        fd = this_fd;
        filesize = size;


        portion_sz = PAGESIZE * PORTION_PAGES;
        nr_portions = size/portion_sz;

        //Imperfect division of filesize with portion_sz
        //add one bit to accomodate for the last portion in file
        if(size % portion_sz){
                nr_portions += 1;
        }

        access_history = BitArrayCreate(nr_portions);
        BitArrayClearAll(access_history);

#if defined(READAHEAD_INFO_PC_STATE) && !defined(PER_INODE_BITMAP)
        page_cache_state = BitArrayCreate(NR_BITS_PREALLOC_PC_STATE);
        BitArrayClearAll(page_cache_state);
#else
        page_cache_state = NULL;
#endif

        //Assume any opened file is probably not sequential
        sequentiality = MAYBESEQ;
        stride = 0;
        read_size = 0;

        last_ra_offset = 0;
        last_read_offset = 0;
}


/*
 * file_predictor's destructor
 */
file_predictor::~file_predictor(){
        BitArrayDestroy(access_history);

#ifdef READAHEAD_INFO_PC_STATE
        BitArrayDestroy(page_cache_state);
#endif
}


/*
 * If offset being accessed is from an Unset file portion, set it,
 * 1. Set that file portion in access_history
 * 2. reduce the sequentiality
 *
 * else increase the sequentiality
 *
 */
void file_predictor::predictor_update(off_t offset, size_t size){

#if 0
        /*
         * Once the file is sent for prefetching
         * there is no point in keeping the prefetcher running for this file
         * TODO: test only works for C++20
         */
        if(already_prefetched.test()){
                goto exit;
        }
#endif


        size_t portion_num = offset/portion_sz; //which portion
        size_t num_portions = size/portion_sz; //how many portions in this req
        size_t pn = 0; //used for adjacency check

        if(portion_num > nr_portions){
                printf("%s: ERR : portion_num > nr_portions, has the filesize changed ?\n", __func__);
                goto exit;
        }

        /*
         * Go through the bit array, setting ones portions associated
         * with this read request
         */
        for(long i=0; i<=num_portions; i++)
                BitArraySetBit(access_history, portion_num+i);

        /*
         * Determine if this sequential or strided
         * TODO: Convert this to a bit operation, this is heavy
         * Develop a bit mask and test the corresponding bits
         */
        for(long i = 1; i <= NR_ADJACENT_CHECK; i++){

                pn = portion_num - i;

                /*bounds check*/
                if((long)pn < 0){
                        goto exit;
                }

                if(BitArrayTestBit(access_history, pn)){
                        stride = portion_num - pn - 1;
                        if(stride > 0)
                                read_size = size;
                        //debug_printf("%s: stride=%ld\n", __func__, stride);
                        goto is_seq;
                }

        }

is_not_seq:
        //sequentiality -= 1;
        //sequentiality %= (DEFNSEQ-1); //Keeps from underflowing
        sequentiality = (std::max<long>)(DEFNSEQ, sequentiality-1); //keeps from underflowing
        goto exit;

is_seq:
        //if(sequentiality < DEFSEQ)
        //sequentiality += 1;
        //sequentiality %= (DEFSEQ+1); //Keeps from overflowing
        sequentiality = (std::min<long>)(DEFSEQ, sequentiality+1); //keeps from overflowing

exit:
        return;
}


//Returns the current Sequentiality value
long file_predictor::is_sequential(){
        return sequentiality;
}


//returns the approximate stride in pages
//0 if not strided. doesnt mean its not sequential
long file_predictor::is_strided(){
        return stride*PORTION_PAGES;
}



bool file_predictor::should_prefetch_now(){

        off_t early_fetch = NR_EARLY_FETCH_PAGES * PAGESIZE;

        printf("%s: entered\n", __func__);

        prefetch_limit = std::max(0L, early_fetch * sequentiality);

        if ((last_read_offset <= (last_ra_offset - early_fetch)) && prefetch_limit > 0){
                return true;
        }

        return false;
}

#endif //PREDICTOR
