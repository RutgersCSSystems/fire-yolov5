#include <fstream>
#include <string>
#include <fcntl.h>
#include <unistd.h>
#include "util.hpp"

#include "sequential.hpp"

thread_local off_t pages_readahead = 0;
thread_local int times_prefetch = 0;
thread_local int future_prefetch = 0;
thread_local off_t g_bytes_prefetched=0;


sequential::sequential(void){
	init = false;
}

#if 0
bool sequential::is_sequential(int fd){
    return(exists(fd) && strides[fd].stride == SEQ_ACCESS);
}
#endif


/* if yes, return the stride
 * else return false
 */
off_t sequential::is_strided(int fd){

#if 0
    if(exists(fd) && strides[fd].stride > SEQ_ACCESS
    if((get_seq_likelyness(fd) == true) && strides[fd].stride > SEQ_ACCESS
            && strides[fd].stride < DEFNSEQ)
#endif
    if(get_seq_likelyness(fd) > 0)   
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

    /*if(!exists(fd)){ //FD not seen earlier
        init_fd_maps(fd);
    }*/

    if((is_definitely_seq(fd) != true) && (is_definitely_notseq(fd) != true)) {
    	current_stream[fd].push_back(access);
	update_stride(fd); //calculate the stride
    }//else {
	//printf("%s FD:%d stride %ld\n", __func__, fd, get_seq_likelyness(fd));	
    //}
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

/* Checks if the fd has been seen before */
bool sequential::exists(int fd)
{
    if(!init)
	return false;
    //May have to remove(fd) if result is false
    return ((strides.find(fd) != strides.end()) &&
            (current_stream.find(fd) != current_stream.end()));
}


/* returns the stride 
*/
off_t sequential::get_stride(int fd){

	return strides[fd].stride;
#if 0	
    if(!init)
	return DEFNSEQ;

    if(exists(fd) && strides[fd].stride < DEFNSEQ)
        return strides[fd].stride;
    else
        return DEFNSEQ;
#endif
}


void sequential::init_fd_maps(int fd){
    strides[fd].stride = DEFNSEQ;
    prefetch_fd_map[fd] = 0;
    return;
}

/* returns the prefetched position
*/
off_t sequential::get_prefetch_pos(int fd) {
    return prefetch_fd_map[fd];
}

void sequential::insert_prefetch_pos(int fd, off_t pos) {
    prefetch_fd_map[fd] = pos;
}

int sequential::prefetch_now_fd(void *pfetch_info, int fd) {

    struct pos_bytes curr_access;
    struct msg *dat = (struct msg*)pfetch_info;
    off_t fd_pos = get_prefetch_pos(fd); 	

    curr_access = dat->pos;

    if((curr_access.pos +  curr_access.bytes) < fd_pos) {
	//fprintf(stderr, "Readahead pos %lu curr pos %lu \n", 
	//		fd_pos, ( curr_access.pos +  curr_access.bytes));
	return 0;
    }
    return 1;
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

void sequential::init_seq_likelyness(int fd) {
	fd_access_map[fd] = DEFNSEQ;
}


/*val can be positive or negative? 
 */
int sequential::update_seq_likelyness(int fd, int val) {

	fd_access_map[fd] = fd_access_map[fd] + val;
	return fd_access_map[fd];
}


/* Function gets the likelyness of sequentiality
 * DEFINITELY_XX sets the likelyness of sequentiality or randomness
 * Most likely the caller is going to skip prefetching (random) or increase 
 * prefetching window size (sequential)
 */
long sequential::get_seq_likelyness(int fd) {

	return fd_access_map[fd];
}

bool sequential::is_definitely_seq(int fd) {

	if(fd_access_map[fd] >= DEFSEQ)
		return true;
	else
		return false;
}

bool sequential::is_definitely_notseq(int fd) {

	if(fd_access_map[fd] <= DEFNSEQ)
		return true;
	else
		return false;
}

void sequential::update_stride(int fd) {

        long this_stride = DEFNSEQ, check_stride = DEFNSEQ;
       
       //if(exists(fd) && current_stream[fd].size() > HISTORY){
       if(current_stream[fd].size() > HISTORY){

                auto deq = current_stream[fd];
                auto stream = deq.begin();
		long next_stride = DEFNSEQ;
		long diff = 0;
		long max_stride = 0;
		int seq_history = 0;
		off_t this_stride_off = 0;

		//printf("***************\n");

		//FIXME: Currently not sure why the current_stream size is less than 2 
                for(int i=0; i < current_stream[fd].size()-3; i++){

                        this_stride = stream->pos; //Pos1 + Size1
			this_stride_off = stream->pos + stream->bytes;

			stream++;
			next_stride = stream->pos;
			diff = next_stride - this_stride;

			/* Check if the difference between current offset and 
			 * previous offset + access bytes is smaller than the 
			 * page size
			 */
			if(next_stride - (long)(this_stride_off) <= PAGESIZE) {
				seq_history++;
			}
			
			if(diff > max_stride) {
				max_stride = diff;
			}
	       }

	    	if(seq_history > 2) { 
			/* pad to atleast a page size */
			if(max_stride < PAGESIZE) {
				max_stride = PAGESIZE;
			}	
			/* increment by one */
			max_stride = max_stride * update_seq_likelyness(fd, 1);
			this_stride = max_stride;

			//printf("PID %d fd: %d this_stride %ld, this_stride_off  %lu next_stride %ld seq_history %d sequence? %ld\n", 
			//	getpid(), fd, this_stride, this_stride_off, next_stride, seq_history, update_seq_likelyness(fd, 1));
		}
	    	else {
			/* reduce by one */
			this_stride = update_seq_likelyness(fd, -1);
		}
               strides[fd].stride = this_stride; //set the new stride
               current_stream[fd].pop_front(); //remove last element
	}
	return;
}


/*seq_prefetch frontend*/
size_t seq_prefetch(struct pos_bytes curr_access, long stride){
    
     /*TODO: Make this malloc scalable
     * without the malloc, the stack memory gets corrupted before
     * the worker threads uses it.
     */
    struct msg *ret = (struct msg*)malloc(sizeof(struct msg));
    size_t bytes_fetched = 0;

    if(!ret)
	    return 0;
    
    ret->pos = curr_access;
    ret->stride = stride;

#ifdef __NO_BG_THREADS
     __seq_prefetch((struct msg*)ret); //Correct
     bytes_fetched = ret->prefetch_bytes;
    free(ret);
    ret = NULL;
#else
    //return thpool_add_work(get_thpool(), __seq_prefetch, &ret);
    thpool_add_work(get_thpool(), __seq_prefetch, (struct msg*)ret);
    bytes_fetched = ret->prefetch_bytes;
#endif

    //FIXME: Who releases the memory of allocated msg?
    return bytes_fetched;
}

void infinite_loop(void *num){
	unsigned long int a;

	for(a=0; a<2000000000000; a++)
	{
		sleep(100);
	}
	printf("a = %lu\n", a);

}



#if 1
/*
 * This function will prefetch for strided/seq accesses
 * returns 0 at success, -1 at failure
 */
//bool __seq_prefetch(struct pos_bytes curr_access, off_t stride){
void __seq_prefetch(void *pfetch_info){

    struct msg *dat = (struct msg*)pfetch_info;
    struct pos_bytes curr_access = dat->pos;
    off_t stride = dat->stride;

    if(stride < 0)
        return;

    //initialize times_prefetch
    if(times_prefetch == 0)
    {
	    char *times = getenv(ENV_PREFETCH);
	    if(!times)
		times_prefetch = DEFAULT_TIMES_PREFETCH;
	    else
		times_prefetch = atoi(times);
    }

    //initialize future_prefetch
    if(future_prefetch == 0)
    {
	    char *future = getenv(ENV_FUTURE);
	    if(!future)
		future_prefetch = DEFAULT_FUTURE_PREFETCH;
	    else
		future_prefetch = atoi(future);
    }

    size_t bytes_toread = stride * times_prefetch;

    if(bytes_toread <= 0){
	    printf("ERROR: %s: bytes_toread <= 0 \n", __func__);
	    return;
    }

    pages_readahead += (bytes_toread >> PAGESHIFT);

    /*print number of readahead pages*/
    printf("nr_pages_readahead %lu bytes_toread %zu\n", pages_readahead, bytes_toread);

    //do readhead

    enable_lib_prefetch = true;
    readahead(curr_access.fd, curr_access.pos, bytes_toread);
    enable_lib_prefetch = false;
    g_bytes_prefetched = bytes_toread;
    dat->prefetch_bytes = bytes_toread;

    return;
}
#else
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

    //initialize future_prefetch
    if(future_prefetch == 0)
    {
	    char *future = getenv(ENV_FUTURE);
	    if(!future)
		future_prefetch = DEFAULT_FUTURE_PREFETCH;
	    else
		future_prefetch = atoi(future);
    }


    off_t nextpos = curr_access.pos + curr_access.bytes + (stride * future_prefetch);
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
    printf("nr_pages_readahead %lu bytes_toread %zu\n", pages_readahead, bytes_toread);

    //do readhead
    readahead(curr_access.fd, nextpos, bytes_toread);
    //return posix_fadvise(curr_access.fd, nextpos, pages_readahead*4096, POSIX_FADV_SEQUENTIAL);
    g_bytes_prefetched = bytes_toread;

    return;
}
#endif
