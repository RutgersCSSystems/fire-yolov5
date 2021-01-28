#include <bits/stdc++.h>
#include <fstream>
#include <string>
#include "util.hpp"

#include "sequential.hpp"


bool sequential::is_sequential(int fd){
    return(exists(fd) && strides[fd].stride == SEQ_ACCESS);
}


int sequential::is_strided(int fd){
    if(exists(fd) && strides[fd].stride > SEQ_ACCESS)
        return strides[fd].stride;
    else
        return NOT_SEQ;
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


/*
 */
off_t sequential::get_stride(int fd){
    if(exists(fd))
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
        long this_stride, check_stride;
        auto deq = current_stream[fd];
        auto stream = deq.begin();

        this_stride = stream->pos + stream->bytes; //Pos1 + Size1
        stream++;
        this_stride = stream->pos - this_stride; //Pos2 - (pos1 + size1)

        for(int i=1; i<HISTORY; i++){
            check_stride = stream->pos + stream->bytes;
            stream++;
            check_stride = stream->pos - check_stride;

#ifdef DEBUG
            printf("fd:%d check_stride:%ld\n", fd, check_stride);
#endif
            if(check_stride != this_stride){
                this_stride = -1;
                break;
            }
        }
        strides[fd].stride = this_stride; //set the new stride
        current_stream[fd].pop_front(); //remove last element
    }
    return;
}


/* Checks if the fd has been seen before
 */
bool sequential::exists(int fd)
{
    //May have to remove(fd) if result is false
    return ((strides.find(fd) != strides.end()) &&
            (current_stream.find(fd) != current_stream.end()));
}
