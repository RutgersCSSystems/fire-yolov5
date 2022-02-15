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

#include <sys/sysinfo.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <sys/resource.h>


#include "predictor.hpp"
#include "worker.hpp"
#include "util.hpp"
#include "frontend.hpp"

#define __NR_start_trace 333
#define __NR_start_crosslayer 448

#define likely(x)      __builtin_expect(!!(x), 1)
#define unlikely(x)    __builtin_expect(!!(x), 0)


#define CLEAR_COUNT     0
#define COLLECT_TRACE 1
#define PRINT_STATS 2
#define PFN_TRACE 4
#define PFN_STAT 5
#define TIME_TRACE 6
#define TIME_STATS 7
#define TIME_RESET 8
#define COLLECT_ALLOCATE 9
#define PRINT_PPROC_PAGESTATS 10

#define ENABLE_FILE_STATS 1
#define DISABLE_FILE_STATS 2
#define RESET_GLOBAL_STATS 3
#define PRINT_GLOBAL_STATS 4
#define CACHE_USAGE_CONS 5
#define CACHE_USAGE_DEST 6
#define CACHE_USAGE_RET 7

#define ENABLE_PVT_LRU 24
#define PRINT_PVT_LRU_STATS 25

/*TODO: Check if this needs to be done using thread_local*/
std::atomic<bool> enable_advise; //Enables and disables application advise
thread_local thread_cons_dest tcd; //Enables thread local constructor and destructor
std::unordered_map<int, bool> *is_reg; //false - this fd is not a regular file
static int is_fdmap_init;

#ifdef ENABLE_CACHE_LIMITING 
/*all of these variables are shared across all threads*/
std::atomic<long> cache_limit; //cache limit set by ENV_CACHE_LIMIT
#endif

struct shared_dat *shared_data; //all shared data across procs/threads

struct prev_ra *prev_ra = NULL; //pointer for shared mem TODO:Recheck need

#ifdef FETCH_WHOLE_FILE
std::unordered_map<int, bool> in_cache; //false - this fd is not in cache completely
char fake_buffer[10];
#endif


/*
 * Thread local variables are constructed at first touch
 * so we will touch them the first time they open a file
 * since for the purposes of this library, we are concerned with
 * threads that deal with opening a file.
 */
void touch_tcd(void){
    if(tcd.test_new)
        tcd.test_new = false;
}

static void con() __attribute__((constructor));
static void dest() __attribute__((destructor));

bool check_fd_reg(int fd)
{
    std::unordered_map<int,bool>::const_iterator it = is_reg->find(fd);
    if (it != is_reg->end() )
            return false;
    else
            return true;
}

/*implemented in linux 5.14*/
void set_crosslayer(){
    syscall(__NR_start_crosslayer, ENABLE_FILE_STATS, 0);
}

/*implemented in linux 5.14*/
void reset_global_stats(){
    syscall(__NR_start_crosslayer, RESET_GLOBAL_STATS, 0);
}

/*implemented in linux 5.14*/
void print_global_stats(){
    syscall(__NR_start_crosslayer, PRINT_GLOBAL_STATS, 0);
}

/*implemented in linux 5.14*/
void unset_crosslayer(){
    syscall(__NR_start_crosslayer, DISABLE_FILE_STATS, 0);
}

/*implemented in linux 4.17*/
void set_pvt_lru(){
    syscall(__NR_start_trace, ENABLE_PVT_LRU, 0);
}


/*enable cache accounting for the calling threads/procs
 * implemented in linux 5.14 (CONFIG_CACHE_LIMITING)
 *
 * It doesnt need any arguments since it just sets
 * task_struct variable do_cache_acct for that process.
 * This is called for both processes (cons)
 * and for threads (thread_cons_dest::thread_cons_dest(void))
 */
void enable_cache_limit(){
    syscall(__NR_start_crosslayer, CACHE_USAGE_CONS, 0);
}

/*disable cache accounting for calling threads/procs 
 * implemented in linux 5.14 (CONFIG_CACHE_LIMITING)
 */
void disable_cache_limit(){
    syscall(__NR_start_crosslayer, CACHE_USAGE_DEST, 0);
}

/*gets cache accounting value
 * implemented in linux 5.14 (CONFIG_CACHE_LIMITING)
 */
long get_cache_usage(){
    return syscall(__NR_start_crosslayer, CACHE_USAGE_RET, 0);
}

/*Thread local constructor*/
thread_cons_dest::thread_cons_dest(void){
    test_new = true;
    nr_readaheads = 0UL;
    mytid = gettid(); //this TID

#ifdef ONLY_SINGLE_PREFETCH_WHOLE
    if(shared_data->first_tid.load() == 0){
        shared_data->first_tid.store(mytid);
    }
#endif

#ifdef CONTROL_PRED
    enable_advise = false; //Disable any app/lib advise by default
#endif

#ifdef CROSSLAYER
    set_crosslayer();
#endif


#ifdef ENABLE_CACHE_LIMITING
    enable_cache_limit();

    /*Testing*/
    //printf("TID:%ld cache limit = %ld\n", mytid, cache_limit.load());
    /*
       printf("%s:%ld to_prefetch_whole set %d\n", __func__, 
       gettid(), shared_data->to_prefetch_whole.load());
       */
#endif
}

thread_cons_dest::~thread_cons_dest(void){
    //int tid = gettid();
    //printf("NR_READAHEADS from %d is %lu\n", tid, nr_readaheads);

#ifdef ENABLE_CACHE_LIMITING
    //call CACHE_USAGE_DEST
    disable_cache_limit();
#endif
}

/*Constructor*/
void con(){

    /*using fprintf here gives SIGFPE for some reason
     * Please dont use fprintf*/
    printf("CONSTRUCTOR GETTING CALLED \n");

    /*Initialize the shared data structure*/
    if(!shared_data){
        shared_data = (struct shared_dat*)mmap(NULL, 
                sizeof(struct shared_dat), PROT_READ | PROT_WRITE, 
                MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        if (shared_data == MAP_FAILED){
            printf("shared_data MMAP failed \n");
        }
    }

#ifdef ONLY_SINGLE_PREFETCH_WHOLE
    shared_data->first_tid.store(0);
#endif


#ifdef MMAP_SHARED_DAT
    //if(is_root_process()){
    if(!prev_ra){
        prev_ra = (struct prev_ra *)mmap(NULL, sizeof(struct prev_ra), PROT_READ | PROT_WRITE,
                MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        if (prev_ra == MAP_FAILED){
            printf("prev_ra MMAP failed \n");
        }
        prev_ra->tid = -1;
        //printf("Done prev_ra=%d\n", prev_ra->fd);
    }
    else{
        while(!prev_ra){
            sleep(1);
        }
        //printf("Done sleeping prev_ra=%d\n", prev_ra->fd);
    }
#endif

#ifdef CONTROL_PRED
    enable_advise = false; //Disable any app/lib advise by default
#endif

#ifdef CROSSLAYER
    set_crosslayer();
#endif

#ifdef ENABLE_GLOBAL_CACHE_STATS
    reset_global_stats();
#endif

#ifdef ENABLE_CACHE_LIMITING
    enable_cache_limit();

    char *cache_lim = getenv(ENV_CACHE_LIMIT);
    if(!cache_lim){
        cache_limit = LONG_MIN;
    }else{
        cache_limit = atol(cache_lim);
    }

    /* Even if multiple processes enable to_prefetch_whole
     *  at different points in the application run by 
     *  the virtue of process spawning/forking,
     *  if the cache usage is under limit, no harm done
     *  if the cache usage is over limit,
     *  prefetch_whole will be set false immediately
     *
     *  This may be a problem for files that are very large, but otherwise
     *  it should be an acceptable approximate solution for now.
     */
    //to_prefetch_whole = true; //initialize
    shared_data->to_prefetch_whole.store(true);
    printf("%s:%ld to_prefetch_whole set %d\n", __func__, 
            gettid(), shared_data->to_prefetch_whole.load());
#endif

#if defined PREDICTOR && !defined __NO_BG_THREADS
    debug_print("init tracing...\n");

    //set_pvt_lru();

    int nr_workers = 1; //TODO: provide nr_workers from env var
    thread_fn(nr_workers);
#endif
}


/*Destructor*/
void dest(){

#if defined PREDICTOR && !defined __NO_BG_THREADS
    debug_print("application termination...\n");

    clean_state();

    print_readahead_time();

    /*
     * This code snippet prints the Rusage parameters
     * at destruction
     */
    struct rusage Hello;
    if (getrusage(RUSAGE_SELF, &Hello) != 0)
    {
        debug_print("Unable to get rusage\n");
    }

    printf("MaxRSS= %lu KB, "
            "SharedMem= %lu KB, "
            "HardPageFault= %lu\n"
            , Hello.ru_maxrss, Hello.ru_ixrss, Hello.ru_majflt);

    syscall(__NR_start_trace, PRINT_PVT_LRU_STATS, 0);
    syscall(__NR_start_trace, PRINT_PPROC_PAGESTATS, 0);
#endif

#ifdef ENABLE_GLOBAL_CACHE_STATS
    print_global_stats();
#endif

#ifdef ENABLE_CACHE_LIMITING
    printf("cache usage = %ld\n", get_cache_usage());
    disable_cache_limit();
#endif
}

#ifndef DISABLE_INTERCEPTING

ssize_t readahead(int fd, off_t offset, size_t count){
    ssize_t ret = 0;
    /*
       struct timeval time;
       gettimeofday(&time, NULL);
       long ftime = time.tv_sec*1000000 + time.tv_usec;

       printf("%ld microsec: %ld called %s: called for fd:%d - offset: %ld to %ld bytes\n", ftime, gettid(), __func__, fd, offset, count);
       */

#ifdef MMAP_SHARED_DAT
    if(unlikely(prev_ra->tid == 0)){
        prev_ra->tid = tcd.mytid;
        goto perform_ra;
    }
    else if(prev_ra->tid == tcd.mytid){
        goto perform_ra;
    }
    else
        goto done;

#if 0
    pthread_mutex_lock(&prev_ra->lock);
    if(prev_ra->fd == fd && prev_ra->offset == offset){
        pthread_mutex_unlock(&prev_ra->lock);
        goto done;
    }
    else{
        prev_ra->fd = fd;
        prev_ra->offset = offset;
    }
    pthread_mutex_unlock(&prev_ra->lock);
#endif

#endif 

perform_ra:

#ifdef CONTROL_PRED
    if(enable_advise)
#endif
    {
        // printf("%ld microsec: %ld called %s: called for fd:%d - offset: %ld to %ld bytes\n", ftime, gettid(), __func__, fd, offset, count);
        //printf("%ld called %s for %d: %ld bytes \n", tcd.mytid, __func__, fd, count);
        tcd.nr_readaheads += 1;
        ret = real_readahead(fd, offset, count);
    }

done:
    return ret;
}


int posix_fadvise(int fd, off_t offset, off_t len, int advice){
    int ret = 0;

    //printf("%s: called for %d, ADV=%d\n", __func__, fd, advice);

#ifdef CONTROL_PRED
    if(enable_advise)
#endif
    {
#ifdef DISABLE_FADV_RANDOM
        if(advice == POSIX_FADV_RANDOM)
            goto exit;
#endif
        //printf("App trying to advise %d for fd:%d\n", advice, fd);
        ret = real_posix_fadvise(fd, offset, len, advice);
    }

exit:
    return ret;
}


int open(const char *pathname, int flags, ...){
    touch_tcd();

    int fd;
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

#ifdef PREDICTOR
    if(!is_fdmap_init){
        is_reg = new std::unordered_map<int, bool>;
        is_fdmap_init = 1;
    }

    debug_print("%s: TID:%ld open:%s\n", __func__, gettid(), pathname);

    if(reg_fd(fd)){
        is_reg->insert({fd, true});
        handle_open(fd, pathname);
    }
    else{
        is_reg->insert({fd, false});
    }
#endif

#ifdef DISABLE_OS_PREFETCH
    printf("disabling OS prefetch:%d %s:%d\n", POSIX_FADV_RANDOM, pathname, fd);
    real_posix_fadvise(fd, 0, 0, POSIX_FADV_RANDOM);
#endif

#ifdef ENABLE_WILLNEED_OPEN
    printf("WillNEED advise on Open:%d %s:%d\n", POSIX_FADV_WILLNEED, pathname, fd);
    real_posix_fadvise(fd, 0, 0, POSIX_FADV_WILLNEED);
#endif


#ifdef FETCH_WHOLE_FILE
    if(in_cache[fd] == false){
        struct read_ra_req ra_req;
        ra_req.total_cache_usage = 0; 

        in_cache[fd] = true;

        ra_req.ra_pos = 0;
        ra_req.ra_count = INT_MAX;
        ra_req.full_file_ra = true;
#ifdef ENABLE_CACHE_LIMITING
        ra_req.cache_limit = cache_limit.load();
#else
        ra_req.cache_limit = -1; //disables cache limit in kernel
#endif

#ifdef ONLY_SINGLE_PREFETCH_WHOLE
        if(shared_data->first_tid.load() == gettid())
#endif
        {
            pread_ra(fd, &fake_buffer, 5, 0, &ra_req);
        }
    }
#endif

exit:
    return fd;
}


FILE *fopen(const char *filename, const char *mode){
    int fd;
    touch_tcd();

    FILE *ret;
    ret = real_fopen(filename, mode);
    if(!ret)
        return ret;

    fd = fileno(ret);

#ifdef PREDICTOR
    debug_print("%s: TID:%ld open:%s\n", __func__, gettid(), filename);

    if(!is_fdmap_init){
        is_reg = new std::unordered_map<int, bool>;
        is_fdmap_init = 1;
    }

    if(reg_file(ret)){
        is_reg->insert({fd, true});
        handle_open(fd, filename);
    }else{
        is_reg->insert({fd, false});
    }
#endif

    fprintf(stderr, "AFTER %s: TID:%ld open:%s FD %d\n", __func__, gettid(), filename, fd);


#ifdef DISABLE_OS_PREFETCH
    printf("disabling OS prefetch:%d %s:%d\n", POSIX_FADV_RANDOM, filename, fd);
    real_posix_fadvise(fd, 0, 0, POSIX_FADV_RANDOM);
#endif

#ifdef ENABLE_WILLNEED_OPEN
    printf("WillNEED file::%d %s:%d\n", POSIX_FADV_WILLNEED, filename, fd);
    real_posix_fadvise(fd, 0, 0, POSIX_FADV_WILLNEED);
#endif

    return ret;
}


size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream){

    size_t pfetch_size = 0;
    size_t amount_read = 0;
    printf("%s: TID:%ld\n", __func__, gettid());
    amount_read = real_fread(ptr, size, nmemb, stream);
    return amount_read;

    // Perform the actual system call
#ifndef READ_RA
    amount_read = real_fread(ptr, size, nmemb, stream);
#endif

#ifdef PREDICTOR
    debug_print("%s: TID:%ld\n", __func__, gettid());

    int fd = fileno(stream);
    //if(reg_file(stream)){ //this is a regular file
    if (check_fd_reg(fd) == true) {
        pfetch_size = handle_read(fd, ftell(stream), size*nmemb);
    }
#endif

#ifdef READ_RA
    amount_read = fread_ra(ptr, size, nmemb, stream, pfetch_size);
#endif

    return amount_read;
}


ssize_t read(int fd, void *data, size_t size){

    ssize_t amount_read = real_read(fd, data, size);

#ifdef PREDICTOR
    debug_print("%s: TID:%ld\n", __func__, gettid());

     if (check_fd_reg(fd) == true) {
        //printf("TID:%ld fd: %d lseek: %ld bytes: %lu\n", 
	//	 gettid(), fd, lseek(fd, 0, SEEK_CUR), size );
        handle_read(fd, lseek(fd, 0, SEEK_CUR), size);
    }
#endif

    return amount_read;
}


ssize_t pread(int fd, void *data, size_t size, off_t offset){

    ssize_t amount_read;
    size_t pfetch_size = 0;

    //amount_read = real_pread(fd, data, size, offset);
#ifndef READ_RA
    //fprintf(stderr, "%s: TID:%ld\n", __func__, gettid());
    amount_read = real_pread(fd, data, size, offset);
#endif

#ifdef PREDICTOR
    debug_print("%s: TID:%ld\n", __func__, gettid());

    if (check_fd_reg(fd) == true) { 	   
        /*
         * It  has been observed that handle_read
         * is adding significant overheads in pread
         * Hence for now, it has been hard coded
         * to readahead 1 page in addition to
         */
        //pfetch_size = handle_read(fd, offset, size);
        pfetch_size = 4096;
    }
#endif

#ifdef READ_RA
    struct read_ra_req ra_req;
    ra_req.ra_pos = 0;
    ra_req.ra_count = 0;
    //fprintf(stderr, "%s: doing serial prefetch \n", __func__);

    ra_req.ra_count = pfetch_size;
    ra_req.full_file_ra = false;
    ra_req.cache_limit = -1; //disables cache limiting in kernel

    //amount_read = syscall(__PREAD_RA_SYSCALL, fd, data, size, offset, &ra_req);
    amount_read = pread_ra(fd, data, size, offset, &ra_req);
    //printf("%s: doing serial prefetch for size %zu offset %d  \n", 
	//	    __func__, ra_req.ra_count, offset);
#endif

    return amount_read;
}


size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){ 

    // Perform the actual system call
    size_t amount_written = real_fwrite(ptr, size, nmemb, stream);

#ifdef PREDICTOR
    debug_print("%s: TID:%ld\n", __func__, gettid());

    /*XXX: handle after read_write will probably
     * change the ftell position in file*/
    int fd = fileno(stream);
    if (check_fd_reg(fd) == true) {
        handle_write(fd, ftell(stream), size*nmemb);
    }
#endif

    return amount_written;
}


ssize_t write(int fd, const void *data, size_t size){

    ssize_t amount_written = real_write(fd, data, size);

#ifdef PREDICTOR
    debug_print("%s: TID:%ld\n", __func__, gettid());

    /*XXX: handle after read_write will probably
     * change the lseek position in file*/
    //if(reg_fd(fd)){
    if (check_fd_reg(fd) == true) {
        handle_write(fd, lseek(fd, 0, SEEK_CUR), size);
    }
#endif
    return amount_written;
}

int fclose(FILE *stream){
    int fd = fileno(stream);
#ifdef PREDICTOR
    debug_print("%s PID:%d fd:%d\n", __func__, getpid(), fd);

    if (check_fd_reg(fd) == true) {
        handle_close(fd);
        is_reg->insert({fd, false});
    }
#endif
    return real_fclose(stream);
}


int close(int fd){
#ifdef PREDICTOR
    debug_print("%s: TID:%ld\n", __func__, gettid());

    if (check_fd_reg(fd) == true) {
        handle_close(fd);
        is_reg->insert({fd, false});
    }
#endif
    return real_close(fd);
}


uid_t getuid(){
#ifdef MMAP_SHARED_DAT
    prev_ra->tid = 0;
#endif
    printf("getuid called by %ld\n", gettid());

    return real_getuid();
}

#endif //DISABLE_INTERCEPTING
