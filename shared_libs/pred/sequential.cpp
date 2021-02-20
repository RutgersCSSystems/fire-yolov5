#include <fstream>
#include <string>
#include <fcntl.h>
#include "util.hpp"

#include "sequential.hpp"

off_t pages_readahead = 0;

bool sequential::is_sequential(int fd){
    return(exists(fd) && strides[fd].stride == SEQ_ACCESS);
}


/* if yes, return the stride
 * else return false
 */
off_t sequential::is_strided(int fd){
    if(exists(fd) && strides[fd].stride > SEQ_ACCESS
            && strides[fd].stride < NOT_SEQ)
        return strides[fd].stride;
    else
        return false;
}


/*Insert a new access to the current_stream
 * Also update stride based on current_stream
 */
void sequential::insert(struct pos_bytes access){
    int fd = access.fd;

    if(!exists(fd)){ //FD not seen earlier
        init_stride(fd);
    }

    current_stream[fd].push_back(access);

    update_stride(fd); //calculate the stride

    debug_print("seq::insert: fd:%d, stride:%lu\n", 
            fd, strides[fd].stride);

    return;
}


/* fd is invalid now, remove it from the data
*/
void sequential::remove(int fd)
{
    strides.erase(fd);
    current_stream.erase(fd);
    return;
}


/* prints all the fd and their strides
*/
void sequential::print_all_strides(){
    for(auto a : strides){
        std::cout << "Stride for fd" << a.first << ": ";
        std::cout << get_stride(a.first) << std::endl;
    }
}


/* returns the stride 
*/
off_t sequential::get_stride(int fd){
    if(exists(fd) && strides[fd].stride < NOT_SEQ)
        return strides[fd].stride;
    else
        return NOT_SEQ;
}


void sequential::init_stride(int fd){
    strides[fd].stride = NOT_SEQ;
    return;
}


void sequential::update_stride(int fd){
    if(exists(fd) && current_stream[fd].size() > HISTORY){
        off_t this_stride, check_stride;
        auto deq = current_stream[fd];
        auto stream = deq.begin();

        this_stride = stream->pos + stream->bytes; //Pos1 + Size1
        stream++;
        this_stride = stream->pos - this_stride; //Pos2 - (pos1 + size1)

        for(int i=1; i<HISTORY; i++){
            check_stride = stream->pos + stream->bytes;
            /*
#ifdef DEBUG
printf("update_stride: fd:%d, pos:%lu, bytes:%lu\n",
fd, stream->pos, stream->bytes);
#endif
*/
            stream++;
            check_stride = stream->pos - check_stride;
            /*
#ifdef DEBUG
printf("update_stride: fd:%d, new_pos:%lu, check_stride:%lu\n",
fd, stream->pos, check_stride);

printf("fd:%d check_stride:%lu\n", fd, check_stride);
#endif
*/
            if(check_stride != this_stride){
                this_stride = NOT_SEQ;
                break;
            }
        }
        strides[fd].stride = this_stride; //set the new stride
        current_stream[fd].pop_front(); //remove last element
    }
    return;
}


/* Checks if the fd has been seen before */
bool sequential::exists(int fd)
{
    //May have to remove(fd) if result is false
    return ((strides.find(fd) != strides.end()) &&
            (current_stream.find(fd) != current_stream.end()));
}


/*
 * This function will prefetch for strided/seq accesses
 * returns 0 at success, -1 at failure
 */
bool seq_prefetch(struct pos_bytes curr_access, off_t stride){

    if(stride < 0)
        return -1;

    off_t nextpos = curr_access.pos + curr_access.bytes + stride;

    //find the next page aligned position
    //nextpos = (PAGESIZE - (nextpos%PAGESIZE)) + nextpos;
    nextpos = ((nextpos >> PAGESHIFT)) << PAGESHIFT; 


    size_t bytes_toread = ((curr_access.bytes >> PAGESHIFT)+1) << PAGESHIFT;
    //size_t bytes_toread = PAGESIZE*NR_READ_PAGES;

    pages_readahead += bytes_toread >> PAGESHIFT;

    debug_print("seq_pefetch: stride:%lu, currpos:%lu, nextpos:%lu, bytes:%zu\n", 
            stride, curr_access.pos, nextpos, bytes_toread);

    fprintf(stderr, "seq_pefetch: stride:%lu, currpos:%lu, nextpos:%lu, bytes:%zu\n", 
            stride, curr_access.pos, nextpos, bytes_toread);

    /*print number of readahead pages*/
    debug_print("nr_pages_readahead %lu\n", pages_readahead);

    return readahead(curr_access.fd, nextpos, bytes_toread); //Do readahead
}
