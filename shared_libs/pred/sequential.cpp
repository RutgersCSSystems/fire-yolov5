#include <fstream>
#include <string>
#include <fcntl.h>
#include <unistd.h>
#include "util.hpp"

#include "sequential.hpp"

off_t pages_readahead = 0;
int times_prefetch = 0;
off_t g_bytes_prefetched=0;


sequential::sequential(void){
	init = false;
}

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

    init = true;

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
    debug_print("%s FD:%d\n", __func__, fd);
    if(init)
    {
	strides.erase(fd);
    	current_stream.erase(fd);
    }
    return;
}


/* prints all the fd and their strides
*/
void sequential::print_all_strides(){
    if(!init)
	return;

    for(auto a : strides){
        std::cout << "Stride for fd" << a.first << ": ";
        std::cout << get_stride(a.first) << std::endl;
    }
}


/* returns the stride 
*/
off_t sequential::get_stride(int fd){
    if(!init)
	return NOT_SEQ;

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
        off_t this_stride = NOT_SEQ, check_stride = NOT_SEQ;
        current_stream[fd].read_window(present_hist, HISTORY);
        //auto deq = current_stream[fd];
        //auto stream = deq.begin();

        /*
        this_stride = stream->pos + stream->bytes; //Pos1 + Size1
        stream++;
        this_stride = stream->pos - this_stride; //Pos2 - (pos1 + size1)
        */

        for(int i=0; i<HISTORY-1; i++){
            if(this_stride == NOT_SEQ)
            {
                this_stride = present_hist[i].pos + present_hist[i].bytes;
                this_stride = present_hist[i+1].pos - this_stride;
                continue;
            }
            check_stride = present_hist[i].pos + present_hist[i].bytes;
            //check_stride = stream->pos + stream->bytes;
            check_stride = present_hist[i+1].pos - check_stride;
            //check_stride = stream->pos - check_stride;
            if(check_stride != this_stride){
                this_stride = NOT_SEQ;
                break;
            }
        }
        strides[fd].stride = this_stride; //set the new stride
        //current_stream[fd].pop_front(); //remove last element
    }
    return;
}


/* Checks if the fd has been seen before */
bool sequential::exists(int fd)
{
    if(!init)
	return false;
    //May have to remove(fd) if result is false
    return ((strides.find(fd) != strides.end()) &&
            (current_stream.find(fd) != current_stream.end()));
}


/*seq_prefetch frontend*/
bool seq_prefetch(struct pos_bytes curr_access, off_t stride){
    /*TODO: Make this malloc scalable
     * without the malloc, the stack memory gets corrupted before
     * the worker threads uses it.
     */
    struct msg *ret = (struct msg*)malloc(sizeof(struct msg));
    ret->pos = curr_access;
    ret->stride = stride;

#ifdef __NO_BG_THREADS
    //__seq_prefetch(&ret);
    __seq_prefetch((struct msg*)ret); //Correct
#else
    //return thpool_add_work(get_thpool(), __seq_prefetch, &ret);
    return thpool_add_work(get_thpool(), __seq_prefetch, (struct msg*)ret);
    //return thpool_add_work(get_thpool(), infinite_loop, NULL);
#endif
    return true;
}

void infinite_loop(void *num){
	unsigned long int a;

	for(a=0; a<2000000000000; a++)
	{
		sleep(100);
	}
	printf("a = %lu\n", a);

}

int prefetch_now(void *pfetch_info) {

    struct pos_bytes curr_access;
    struct msg *dat = (struct msg*)pfetch_info;	

    if(!dat)
	    return true;

    curr_access = dat->pos;

    if(g_bytes_prefetched > curr_access.bytes) {
	g_bytes_prefetched = g_bytes_prefetched - curr_access.bytes;    
	//fprintf(stderr, "Returning false g_bytes_prefetched %u "
	//		"curr_access.bytes %u\n", g_bytes_prefetched, curr_access.bytes);
	return 0;
    }
 	
    return 1;
}

/*
 * This function will prefetch for strided/seq accesses
 * returns 0 at success, -1 at failure
 */
//bool __seq_prefetch(struct pos_bytes curr_access, off_t stride){
void __seq_prefetch(void *pfetch_info){

    struct msg dat = *(struct msg*)pfetch_info;
    struct pos_bytes curr_access = dat.pos;
    off_t stride = dat.stride;

    if(stride < 0)
        return;

    /*if(g_bytes_prefetched > curr_access.bytes) {
	g_bytes_prefetched = g_bytes_prefetched - curr_access.bytes;
        //printf("g_bytes_prefetched %lu\n", g_bytes_prefetched);
	return;
    }*/

    //initialize times_prefetch
    if(times_prefetch == 0)
    {
	    char *times = getenv(ENV_PREFETCH);
	    if(!times)
		times_prefetch = DEFAULT_TIMES_PREFETCH;
	    else
		times_prefetch = atoi(times);
    }

    off_t nextpos = curr_access.pos + curr_access.bytes + stride;
    off_t nextpos_align = nextpos;

    //find the next page aligned position
    nextpos_align = ((nextpos >> PAGESHIFT)) << PAGESHIFT; 

    size_t bytes_toread = curr_access.bytes;
    //increase the prefetch window by times_prefetch
    bytes_toread *= times_prefetch; 

    if(bytes_toread <= 0){
	    printf("ERROR: %s: bytes_toread <= 0 \n", __func__);
	    return;
    }

    pages_readahead += (bytes_toread >> PAGESHIFT);

    debug_print("%s: stride:%lu, currpos:%lu, nextpos:%lu, bytes:%zu\n", 
            __func__, stride, curr_access.pos, nextpos, bytes_toread);

    /*print number of readahead pages*/
    debug_print("nr_pages_readahead %lu\n", bytes_toread);

    //do readhead
    readahead(curr_access.fd, nextpos, bytes_toread);
    //return posix_fadvise(curr_access.fd, nextpos, pages_readahead*4096, POSIX_FADV_SEQUENTIAL);
    g_bytes_prefetched = bytes_toread;

    return;
}
