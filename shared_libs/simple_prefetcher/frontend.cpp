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

#include "util.hpp"
#include "frontend.hpp"
#include "utils/robin_hood.h"

#ifdef THPOOL_PREFETCH
threadpool workerpool = NULL;
#endif

#ifdef MAINTAIN_UINODE
#include "uinode.hpp"
#include "hashtable.h"
struct hashtable *i_map;
std::atomic_flag i_map_init;
#endif

//Maps fd to its file_predictor, global ds
std::unordered_map<int, file_predictor*> fd_to_file_pred;
std::atomic_flag fd_to_file_pred_init;



//enables per thread constructor and destructor
thread_local per_thread_ds ptd;

static void con() __attribute__((constructor));
static void dest() __attribute__((destructor));

void print_affinity() {
    cpu_set_t mask;
    long nproc, i;

    if (sched_getaffinity(0, sizeof(cpu_set_t), &mask) == -1) {
        perror("sched_getaffinity");
    }
    nproc = sysconf(_SC_NPROCESSORS_ONLN);
    printf("sched_getaffinity = ");
    for (i = 0; i < nproc; i++) {
        printf("%d ", CPU_ISSET(i, &mask));
    }
    printf("\n");
}

/*
 * Handle signals from application to wind-up a
 * bunch of things. For example, filebench does
 * not terminate unless the worker threads terminate
 */
void handle_app_sig_handler(int signum){

  //fprintf(stderr, "Inside handler function\n");
  dest();
#ifdef THPOOL_PREFETCH
  if(workerpool) {
	  thpool_destroy(workerpool);
	  workerpool = NULL;
  }
#endif
  //fprintf(stderr, "Finished destruction\n");
  return;
}

void reg_app_sig_handler(void){

	//fprintf(stderr, "Regsitering signal handler \n");
	//signal(SIGUSR2,handle_app_sig_handler);
}


/*
 * Initialize fd_to_file_pred
 */
void init_global_ds(void){

	if(!fd_to_file_pred_init.test_and_set()){
		debug_printf("%s:%d Allocating fd_to_file_pred\n", __func__, __LINE__);
		//fd_to_file_pred = new std::unordered_map<int, file_predictor*>;
	}

	if(!i_map_init.test_and_set()){
		debug_printf("%s:%d Allocating hashmap\n", __func__, __LINE__);
		i_map = init_inode_fd_map();
		if(!i_map){
			fprintf(stderr, "%s:%d Hashmap alloc failed\n", __func__, __LINE__);
		}
	}
}

/*
 * Set unbounded_read to 0 or 1
 */
void set_read_limits(char a){

	debug_printf("%s: Setting Read Limits to %c\n", __func__, a);
	int fd = real_open(LIMITS_PROCFS_FILE, O_RDWR, 0);
	pwrite(fd, &a, sizeof(char), 0);
	real_close(fd);
	debug_printf("Exiting %s\n", __func__);
}


void con(){

	char a;

#ifdef ENABLE_OS_STATS
	fprintf(stderr, "ENABLE_FILE_STATS in %s\n", __func__);
	syscall(__NR_start_crosslayer, ENABLE_FILE_STATS, 0);
#endif

	debug_printf("CONSTRUCTOR GETTING CALLED \n");
	/*
	 * Sometimes, if dlsym is called with thread spawn
	 * glibc incurres an error.
	 */
	link_shim_functions();

#ifdef THPOOL_PREFETCH
	workerpool = thpool_init(NR_WORKERS);
	if(!workerpool){
		printf("%s:FAILED creating thpool with %d threads\n", __func__, NR_WORKERS);
	}
	else{
		debug_printf("Created %d bg_threads\n", NR_WORKERS);
	}
#endif
	init_global_ds();

#ifdef SET_READ_UNLIMITED
	a = '1';
	set_read_limits(a);
#else
	a = '0';
	set_read_limits(a);
#endif
	//print_affinity();

	/* register application specific handler */
	reg_app_sig_handler();
}


void dest(){
        /*
         * Reset the IO limits to normal
         */
        char a;
        a = '0';
        set_read_limits(a);
        fprintf(stderr, "DESTRUCTOR GETTING CALLED \n");
        debug_printf("DESTRUCTOR GETTING CALLED \n");

#ifdef ENABLE_OS_STATS
	fprintf(stderr, "PRINT_GLOBAL_STATS in %s\n", __func__);
	syscall(__NR_start_crosslayer, PRINT_GLOBAL_STATS, 0);
	syscall(__NR_start_crosslayer, CLEAR_GLOBAL_STATS, 0);
#endif

}


#ifdef ENABLE_EVICTION
int set_thread_args_evict(struct thread_args *arg) {
		arg->current_fd = ptd.current_fd;
		arg->last_fd = ptd.last_fd;
		return 0;
}

int set_curr_last_fd(int fd){
	/*
	 * The first time ptd is accessed by a thread(clone)
	 * it calls its constructor.
	 */
	if(ptd.last_fd == 0){
		ptd.last_fd = fd;
		ptd.current_fd = fd;
	}
	else{
		/*
		 * Update the current and last fd
		 * for this thread each time it reads
		 *
		 * Heuristic: If the thread moves on to
		 * another fd, it is likely done with last_fd
		 * ie. in an event of memory pressure, cleanup that
		 * file from memory
		 */
		ptd.last_fd = ptd.current_fd;
		ptd.current_fd = fd;
	}
	return 0;
}

int evict_advise(int fd){

	//printf("%s:%d Evicting using fadvice fd:%d\n", __func__, __LINE__, fd);
	return posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
}

int perform_eviction(struct thread_args *arg){
	/*
	 * when crunched with memory, remove cache pages for
	 * last fd. Since the thread has moved on from it.
	 */
	if(arg->current_fd != arg->last_fd){
		debug_printf("%s: Evicting fd:%d\n", __func__, arg->last_fd);
		evict_advise(arg->last_fd);
	}

	return 0;
}
#endif


/*
 * function run by the prefetcher thread
 */
#ifdef CONCURRENT_PREFETCH
void *prefetcher_th(void *arg) {
#else //THPOOL needs void 
void prefetcher_th(void *arg) {
#endif

	long tid = gettid();
	struct thread_args *a = (struct thread_args*)arg;

	debug_printf("TID:%ld: going to fetch from %ld for size %ld on file %d, rasize = %ld, stride = %ld bytes\n",
			tid, a->offset, a->file_size, a->fd, a->prefetch_size, a->stride);

	off_t curr_pos = 0;
	off_t file_pos; //actual file position where readahead will be done
	size_t readnow;
	struct read_ra_req ra;

	off_t start_pg; //start from here in page_cache_state
	off_t zero_pg; //first zero bit found here
	off_t pg_diff;

	bit_array_t *page_cache_state = NULL;
	/*
	 * Allocate page cache bitmap if you want to use it without predictor
	 */
#if defined(MODIFIED_RA) && defined(READAHEAD_INFO_PC_STATE) && !defined(PREDICTOR)
	//printf(stderr, "%s: defining bitarray in worker %ld\n", __func__, NR_BITS_PREALLOC_PC_STATE);
	page_cache_state = BitArrayCreate(NR_BITS_PREALLOC_PC_STATE);
	BitArrayClearAll(page_cache_state);
	//printf(stderr, "%s: DONE defining bitarray in worker %ld\n", __func__, NR_BITS_PREALLOC_PC_STATE);
#elif defined(MODIFIED_RA) && defined(READAHEAD_INFO_PC_STATE) && defined(PREDICTOR)
	page_cache_state = a->page_cache_state;
#else
	page_cache_state = NULL;
#endif

	file_pos = curr_pos + a->offset;

	while (file_pos < a->file_size){
#ifdef MODIFIED_RA

		if(page_cache_state){
			ra.data = page_cache_state->array;
		}else{
			ra.data = NULL;
		}

		if(readahead_info(a->fd, file_pos,
				a->prefetch_size, &ra) < 0)
		{
			printf("readahead_info: failed TID:%ld \n", tid);
			goto exit;
		}
                /*
                else {
			printf(" readahead_info: TID:%ld succeeded \n", tid);
		}
                */
#ifdef READAHEAD_INFO_PC_STATE
		page_cache_state->array = (unsigned long*)ra.data;
		start_pg = file_pos >> PAGE_SHIFT;
		zero_pg = start_pg;

		while((zero_pg << PAGE_SHIFT) < a->file_size){
			if(!BitArrayTestBit(page_cache_state, zero_pg))
			{
				break;
			}
			zero_pg += 1;
		}

		pg_diff = zero_pg - start_pg;

		//printf("%s: We have %d pages in the page cache \n", __func__, zero_pg);
		//debug_printf("%s: offset=%ld, pg_diff=%ld, fd=%d \n", __func__, curr_pos, pg_diff, a->fd);

		if(pg_diff > (a->prefetch_size >> PAGE_SHIFT))
			curr_pos += pg_diff << PAGE_SHIFT;
		else
			curr_pos += a->prefetch_size;
#else //READAHEAD_INFO_PC_STATE
		curr_pos += a->prefetch_size;
#endif //READAHEAD_INFO_PC_STATE

		/*
		 * if the memory is less NR_REMAINING
		 * the prefetcher stops
		 */
		if(ra.nr_free < NR_REMAINING)
		{
			debug_printf("%s: Not prefetching any further: fd=%d\n", __func__, a->fd);
#ifdef ENABLE_EVICTION_OLD
			perform_eviction(a);
#else //ENABLE_EVICTION
			goto exit;
#endif //ENABLE_EVICTION
		}

#else //MODIFIED_RA
		if(real_readahead(a->fd, file_pos, a->prefetch_size) < 0){
			//printf("error while readahead: TID:%ld \n", tid);
			goto exit;
		}
		curr_pos += a->prefetch_size;
#endif //MODIFIED_RA
	        file_pos = curr_pos + a->stride;
	}

exit:
#if defined(MODIFIED_RA) && defined(READAHEAD_INFO_PC_STATE) && !defined(PREDICTOR)
	BitArrayDestroy(page_cache_state);
#endif
	free(arg);

	debug_printf("Exiting %s\n", __func__);
}


/*
 * Spawns or enqueues a request for file prefetching
 */
#ifdef PREDICTOR
void inline prefetch_file(int fd, file_predictor *fp)
#else
void inline prefetch_file(int fd)
#endif
{
	struct thread_args *arg = NULL;
	off_t filesize;
    off_t stride;

	debug_printf("Entering %s\n", __func__);
	/*
	 * When PREDICTOR is enabled, file sanity checks are not required
	 * This is because the file has already been screened for
	 * 1. Filesize
	 * 2. Type (regular file etc.)
	 * 3. Sequentiality
	 * This was done at record_open
	 */
#ifdef PREDICTOR
	filesize = fp->filesize;
    stride = fp->is_strided() * fp->portion_sz;
    if(stride < 0){
    	printf("ERROR: %s: stride is %ld, should be > 0\n", __func__, stride);
        stride = 0;
     }
#else
	filesize = reg_fd(fd);
    stride = 0;
#endif
	debug_printf("%s: fd=%d, filesize = %ld, stride= %ld\n", __func__, fd, filesize, stride);

	if(filesize > MIN_FILE_SZ){
		arg = (struct thread_args *)malloc(sizeof(struct thread_args));
		if(!arg) {
			goto prefetch_file_exit;
		}
		arg->fd = fd;
		arg->offset = 0;
		arg->file_size = filesize;
        arg->stride = stride;

#ifdef ENABLE_EVICTION_OLD
        set_thread_args_evict(arg);
#else
		arg->current_fd = 0;
		arg->last_fd = 0;
#endif

#ifdef FULL_PREFETCH
		//Allows the whole file to be prefetched at once
		arg->prefetch_size = filesize;
		printf("%s: Doing a full prefetch %zu bytes\n", __func__, filesize);

#elif PREDICTOR
		/*
		 * FULL_PREFETCH is never used with PREDICTOR
		 * This means PREDICTOR and FULL_PREFETCH is off
		 */

		/*
		 * If the application is doing strided reads
		 * doing large prefetches wastes the IO bandwidth
		 * and also wastes cache memory. To mitigate that,
		 * we shall decrease the prefetch range to the size
		 * of each read done in strided access.
		 */
		if(stride){
			arg->prefetch_size = fp->read_size;
		}
		else{
			/*
			 * The application is doing seq reads,
			 * Whole file prefetched in NR_RA_PAGES bytes
			 */
			//FIXME: CHECK MEMORY AVAILABILITY TOO
			if(fp->is_sequential() == DEFSEQ){
				arg->prefetch_size = arg->file_size;
				//fprintf(stderr, "Fetch the entire file predicted as DEF SEQUENTIALITY \n");
			}else {
				arg->prefetch_size = NR_RA_PAGES * PAGESIZE;
			}
		}
#else
		/*
		 * This is !PREDICTOR and !FULL_PREFETCH
		 * which means prefetch blindly NR_RA_PAGES at a time
		 */
		arg->prefetch_size = NR_RA_PAGES * PAGESIZE;
#endif

#if defined(READAHEAD_INFO_PC_STATE) && defined(PREDICTOR)
		arg->page_cache_state = fp->page_cache_state;
#else
		arg->page_cache_state = NULL;
#endif
	}
	else{
		debug_printf("%s: fd=%d is smaller than %d bytes\n", __func__, fd, MIN_FILE_SZ);
		goto prefetch_file_exit;
	}

#ifdef CONCURRENT_PREFETCH
	pthread_t thread;
	pthread_create(&thread, NULL, prefetcher_th, (void*)arg);
#elif THPOOL_PREFETCH
	//Enlists the prefetching request using the thpool
	if(!workerpool)
		printf("ERR: %s: No workerpool ? \n", __func__);
	else
		thpool_add_work(workerpool, prefetcher_th, (void*)arg);
#else
	prefetcher_th((void*)arg);
	//printf("ERR: in %s; undefined state in CONCURRENT_PREFETCH\n", __func__);
#endif

prefetch_file_exit:
	debug_printf("Exiting %s\n", __func__);
	return;
}



/*
 * Initialize a file_predictor object if
 * the file is > Min_FILE_SZ
 *
 * and init the bitmap inside the kernel
 */
void inline record_open(int fd){

	off_t filesize = reg_fd(fd);
	struct read_ra_req ra;
	struct timespec start, end;

	debug_printf("Entering %s\n", __func__);

	if(filesize > MIN_FILE_SZ){

#ifdef PREDICTOR
		file_predictor *fp = new file_predictor(fd, filesize);

		if(!fp)
			goto exit;

		debug_printf("%s: fd=%d, filesize=%ld, nr_portions=%ld, portion_sz=%ld\n",
				__func__, fp->fd, fp->filesize, fp->nr_portions, fp->portion_sz);

		fd_to_file_pred.insert({fd, fp});
#endif

		/*
		 * This allocates the file's bitmap inside the kernel
		 * So no file cache data is lost from bitmap
		 * This is very important todo before any app reads happen
		 */
#ifdef READAHEAD_INFO_PC_STATE
		debug_printf("%s: first READAHEAD: %ld\n", __func__, ptd.mytid);
		//clock_gettime(CLOCK_REALTIME, &start);
		ra.data = NULL;
		readahead_info(fd, 0, 0, &ra);

		//clock_gettime(CLOCK_REALTIME, &end);
		//debug_printf("%s: DONE first READAHEAD: %ld in %lf microsec new\n", __func__, ptd.mytid, get_micro_sec(&start, &end));
#endif
	}
	else{
		debug_printf("%s: fd=%d is smaller than %d bytes\n", __func__, fd, MIN_FILE_SZ);
//		goto exit;
	}

exit:
	debug_printf("Exiting %s\n", __func__);
	return;
}


/*
 * Does all the extra computing at open
 * for all the open functions
 */
void handle_open(int fd){

	debug_printf("Entering %s\n", __func__);

#ifdef ONLY_INTERCEPT
	return;
#endif

#if defined(PREDICTOR) || defined(READAHEAD_INFO_PC_STATE)
	record_open(fd);
#endif
	/*
	 * DONT compile library with both PREDICTOR and BLIND_PREFETCH
	 */
#ifdef BLIND_PREFETCH
	// Prefetch without predicting
	prefetch_file(fd);
#endif

#ifdef MAINTAIN_UINODE
	add_fd_to_inode(i_map, fd);
#endif

	debug_printf("Exiting %s\n", __func__);
}


//////////////////////////////////////////////////////////
//Intercepted Functions
//////////////////////////////////////////////////////////

int openat(int dirfd, const char *pathname, int flags, ...){

	int fd;

	debug_printf("Entering %s\n", pathname);

	if(flags & O_CREAT){
		va_list valist;
		va_start(valist, flags);
		mode_t mode = va_arg(valist, mode_t);
		va_end(valist);
		fd = real_openat(dirfd, pathname, flags, mode);
	}
	else{
		fd = real_openat(dirfd, pathname, flags, 0);
	}

	if(fd < 0)
		goto exit;

	handle_open(fd);

exit:
	debug_printf("Exiting %s\n", __func__);
	return fd;
}


int open64(const char *pathname, int flags, ...){

	int fd;

	debug_printf("%s: file %s: fd=%d\n", __func__, pathname, fd);

	if(flags & O_CREAT){
		va_list valist;
		va_start(valist, flags);
		mode_t mode = va_arg(valist, mode_t);
		va_end(valist);
		fd = real_open(pathname, flags, mode);
	}
	else{
		fd = real_open(pathname, flags, 0);
	}
	handle_open(fd);

exit:
	debug_printf("Exiting %s\n", __func__);
	return fd;
}


int open(const char *pathname, int flags, ...){

	int fd;

	debug_printf("%s: file %s\n", __func__,  pathname);

	if(flags & O_CREAT){
		va_list valist;
		va_start(valist, flags);
		mode_t mode = va_arg(valist, mode_t);
		va_end(valist);
		fd = real_open(pathname, flags, mode);
	}
	else{
		fd = real_open(pathname, flags, 0);
	}

	if(fd < 0)
		goto exit;
	handle_open(fd);

exit:
	debug_printf("Exiting %s\n", __func__);
	return fd;
}


FILE *fopen(const char *filename, const char *mode){

	int fd;
	FILE *ret;

	debug_printf("%s: file %s\n", __func__,  filename);
	ret = real_fopen(filename, mode);
	if(!ret)
		return ret;

	fd = fileno(ret);
	handle_open(fd);

exit:
	debug_printf("Exiting %s\n", __func__);
	return ret;
}


int posix_fadvise64(int fd, off_t offset, off_t len, int advice){

	int ret = -1;
	debug_printf("%s: called for %d, ADV=%d\n", __func__, fd, advice);
	ret = posix_fadvise(fd, offset, len, advice);
	debug_printf( "Exiting %s\n", __func__);
	return ret;
}


int posix_fadvise(int fd, off_t offset, off_t len, int advice){


	int ret = 0;
	debug_printf("%s: called for %d, ADV=%d\n", __func__, fd, advice);

#ifdef DISABLE_FADV_RANDOM
	if(advice == POSIX_FADV_RANDOM)
		goto exit;
#endif

#ifdef DISABLE_FADV_DONTNEED
	if(advice == POSIX_FADV_DONTNEED)
		goto exit;
#endif

	ret = real_posix_fadvise(fd, offset, len, advice);
exit:
	debug_printf( "Exiting %s\n", __func__);
	return ret;
}


int madvise(void *addr, size_t length, int advice){
	int ret = 0;

	debug_printf("%s: called ADV=%d\n", __func__, advice);

#ifdef DISABLE_MADV_DONTNEED
	if(advice == MADV_DONTNEED)
		goto exit;
#endif

	ret = real_madvise(addr, length, advice);
exit:
    debug_printf( "Exiting %s\n", __func__);
	return ret;
}


ssize_t pread64(int fd, void *data, size_t size, off_t offset){
        return pread(fd, data, size, offset);
}


ssize_t pread(int fd, void *data, size_t size, off_t offset){

	ssize_t amount_read;

	//debug_printf("%s: fd=%d, offset=%ld, size=%ld\n", __func__, fd, offset, size);

#ifdef ONLY_INTERCEPT
	goto skip_predictor;
#endif

#ifdef ENABLE_EVICTION_OLD
	set_curr_last_fd(fd);
#endif


#ifdef PREDICTOR
	init_global_ds();
	file_predictor *fp;
	try{
		fp = fd_to_file_pred.at(fd);
	}
	catch(const std::out_of_range &orr){
		goto skip_predictor;
	}

	if(fp){
		fp->predictor_update(offset, size);
		//if((fp->is_sequential() >= LIKELYSEQ) && (!fp->already_prefetched.test_and_set())){
		if((fp->is_sequential() >= LIKELYSEQ)){
			prefetch_file(fd, fp);
			//printf("%s: seq:%ld\n", __func__, fp->is_sequential());
		}
	}
#endif

skip_predictor:

#ifdef SEQ_PREFETCH
	struct read_ra_req ra_req;
	ra_req.ra_pos = 0;
	ra_req.ra_count = NR_RA_PAGES * PAGESIZE;

	ra_req.full_file_ra = false;
	ra_req.cache_limit = -1; //disables cache limiting in kernel

	amount_read = pread_ra(fd, data, size, offset, &ra_req);
#else
	amount_read = real_pread(fd, data, size, offset);
#endif

exit:
	return amount_read;
}



void handle_file_close(int fd){

	debug_printf("Entering %s\n", __func__);

#ifdef MAINTAIN_UINODE
	int i_fd_cnt = handle_close(i_map, fd);
#ifdef ENABLE_EVICTION
	if(!i_fd_cnt){
		evict_advise(fd);
	}
#endif
#endif


#if 0 //def PREDICTOR
	init_global_ds();
	file_predictor *fp;
	try{
		debug_printf("%s: found fd %d in fd_to_file_pred\n", __func__, fd);
		//fp = fd_to_file_pred.at(fd);
		//fd_to_file_pred->erase(fd);
	}
	catch(const std::out_of_range){
		debug_printf("%s: unable to find fd %d in fd_to_file_pred\n", __func__, fd);
		goto exit;
	}
	if(fp){
		delete(fp);
	}
#endif

exit:
	debug_printf("Exiting %s\n", __func__);
	return;
}



void read_predictor(FILE *stream, size_t data_size) {

	size_t amount_read = 0;
	int fd = fileno(stream);

	debug_printf("%s: TID:%ld\n", __func__, gettid());

#ifdef ONLY_INTERCEPT
	goto skip_read_predictor;
#endif

	/*
	 * Sanity check
	 */
	if(fd < 3){
		goto skip_read_predictor;
	}

#ifdef ENABLE_EVICTION_OLD
	set_curr_last_fd(fd);
#endif

#ifdef PREDICTOR
	file_predictor *fp;
	try{
		fp = fd_to_file_pred.at(fd);
	}
	catch(const std::out_of_range &orr){
		goto skip_read_predictor;
	}

	if(fp){
		fp->predictor_update(ftell(stream), data_size);
		if((fp->is_sequential() >= LIKELYSEQ) && (!fp->already_prefetched.test_and_set())){
			prefetch_file(fd, fp);
			debug_printf("%s: seq:%ld\n", __func__, fp->is_sequential());
		}
	}
#endif

skip_read_predictor:
	return;
}


/*Several applications use fgets*/
char *fgets( char *str, int num, FILE *stream ) {

    debug_printf( "Exiting %s\n", __func__);

    read_predictor(stream, (size_t)num);	

    return real_fgets(str, num, stream);
}

size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream){


	size_t amount_read = 0;
	int fd = fileno(stream);

	debug_printf("%s: TID:%ld\n", __func__, gettid());

#ifdef ONLY_INTERCEPT
	goto skip_predictor;
#endif

	/*
	 * Sanity check
	 */
	if(fd < 3){
		goto skip_predictor;
	}

#ifdef ENABLE_EVICTION_OLD
	set_curr_last_fd(fd);
#endif

#ifdef PREDICTOR
	//init_global_ds();
	file_predictor *fp;
	try{
		fp = fd_to_file_pred.at(fd);
	}
	catch(const std::out_of_range &orr){
		goto skip_predictor;
	}

	if(fp){
		fp->predictor_update(ftell(stream), size*nmemb);
		if((fp->is_sequential() >= LIKELYSEQ) && (!fp->already_prefetched.test_and_set())){
			prefetch_file(fd, fp);
			debug_printf("%s: seq:%ld\n", __func__, fp->is_sequential());
		}
	}
#endif

skip_predictor:
    amount_read = real_fread(ptr, size, nmemb, stream);

exit:
	debug_printf( "Exiting %s\n", __func__);
	return amount_read;
}






int fclose(FILE *stream){

	int fd = fileno(stream);

	debug_printf( "Entering %s\n", __func__);

#ifdef ONLY_INTERCEPT
	goto exit;
#endif
	debug_printf("%s: closing %d\n", __func__, fd);
	handle_file_close(fd);

exit:
	debug_printf( "Exiting %s\n", __func__);
	return real_fclose(stream);
}


int close(int fd){

	debug_printf("Entering %s\n", __func__);

#ifdef ONLY_INTERCEPT
	goto exit;
#endif

	handle_file_close(fd);
exit:
	debug_printf( "Exiting %s\n", __func__);
	return real_close(fd);
}


ssize_t readahead(int fd, off_t offset, size_t count){


	ssize_t ret = 0;

	debug_printf("Entering %s\n", __func__);
#ifdef DISABLE_APP_READAHEADS
	goto exit;
#endif
	ret = real_readahead(fd, offset, count);

exit:
	debug_printf( "Exiting %s\n", __func__);
	return ret;
}
