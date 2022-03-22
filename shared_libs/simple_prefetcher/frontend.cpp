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

#include "util.hpp"
#include "frontend.hpp"
#include "utils/robin_hood.h"

#ifdef THPOOL_PREFETCH
threadpool workerpool = NULL;
#endif

//Maps fd to its file_predictor
//robin_hood::unordered_node_map<int, file_predictor*> fd_to_file_pred;
std::unordered_map<int, file_predictor*> fd_to_file_pred;

//enables per thread constructor and destructor
//thread_local per_thread_ds tcd;

static void con() __attribute__((constructor));
static void dest() __attribute__((destructor));


void con(){
        printf("CONSTRUCTOR GETTING CALLED \n");

#ifdef THPOOL_PREFETCH
        //workerpool = create_thpool(NR_WORKERS);
        workerpool = thpool_init(NR_WORKERS);
        if(!workerpool){
                printf("%s:FAILED creating thpool with %d threads\n", __func__, NR_WORKERS);
        }
        else{
                debug_printf("Created %d bg_threads\n", NR_WORKERS);
        }
#endif

}

void dest(){
        printf("DESTRUCTOR GETTING CALLED \n");
}


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
        debug_printf("TID:%ld: going to fetch from %ld for size %ld on file %d, rasize = %ld\n", 
                        tid, a->offset, a->file_size, a->fd, a->prefetch_size);

        off_t curr_pos = 0;
        size_t readnow;
        struct read_ra_req ra;


#ifdef PREFETCH_READAHEAD
        while (curr_pos < a->file_size){
#ifdef MODIFIED_RA
                if(readahead_info(a->fd, (curr_pos + a->offset), 
                                        a->prefetch_size, &ra) > 0)
                {
                        printf("error while readahead_info: TID:%ld \n", tid);
                        goto exit;
                }

                /*
                 * if the memory is less NR_REMAINING
                 * the prefetcher stops
                 */
                if(ra.nr_free < NR_REMAINING)
                {
                        printf("%s: Not prefetching any further: fd=%d\n", __func__, a->fd);
                        goto exit;
                }
#else
                if(real_readahead(a->fd, (curr_pos + a->offset), a->prefetch_size) > 0){
                        printf("error while readahead: TID:%ld \n", tid);
                        goto exit;
                }
#endif
                curr_pos += a->prefetch_size;
        }
#endif
exit:
        free(arg);
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
#else
        filesize = reg_fd(fd);
#endif

        if(filesize > MIN_FILE_SZ){
                arg = (struct thread_args *)malloc(sizeof(struct thread_args));
                arg->fd = fd;
                arg->offset = 0;
                arg->file_size = filesize;
#ifdef FULL_PREFETCH
                //Allows the whole file to be prefetched at once
                arg->prefetch_size = filesize;
#else
                //Whole file prefetched in NR_RA_PAGES bites
                arg->prefetch_size = NR_RA_PAGES * PAGESIZE;
#endif
        }
        else{
                debug_printf("%s: fd=%d is smaller than %ld bytes\n", __func__, fd, MIN_FILE_SZ);
                goto exit;
        }

#ifdef CONCURRENT_PREFETCH
        pthread_t thread;
        pthread_create(&thread, NULL, prefetcher_th, (void*)arg);
#elif THPOOL_PREFETCH
        //Enlists the prefetching request using the thpool
        if(!workerpool)
                printf("%s: No workerpool ? \n", __func__);
        else
                thpool_add_work(workerpool, prefetcher_th, (void*)arg);
#endif

exit:
        return;
}


/*
 * Initialize a file_predictor object if
 * the file is > Min_FILE_SZ
 */
void inline record_open(int fd){
        off_t filesize = reg_fd(fd);

        if(filesize > MIN_FILE_SZ){

                file_predictor *fp = new file_predictor(fd, filesize);

                debug_printf("%s: fd=%d, filesize=%ld, nr_portions=%ld, portion_sz=%ld\n",
                                __func__, fp->fd, fp->filesize, fp->nr_portions, fp->portion_sz);

                fd_to_file_pred[fd] = fp;
        }
        else{
                debug_printf("%s: fd=%d is smaller than %ld bytes\n", __func__, fd, MIN_FILE_SZ);
                goto exit;
        }

exit:
        return;
}




//////////////////////////////////////////////////////////
//Intercepted Functions
//////////////////////////////////////////////////////////


int open(const char *pathname, int flags, ...){
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

        debug_printf("Opening file %s\n", pathname);


#ifdef PREDICTOR
        // Predict, then prefetch if needed
        record_open(fd);

#elif BLIND_PREFETCH
        // Prefetch without predicting
        prefetch_file(fd);
#endif

exit:
        return fd;
}


FILE *fopen(const char *filename, const char *mode){
        int fd;

        FILE *ret;
        ret = real_fopen(filename, mode);
        if(!ret)
                return ret;

        debug_printf("FOpening file\n");

        fd = fileno(ret);

#ifdef PREDICTOR
        // Predict, then prefetch if needed
        record_open(fd);

#elif BLIND_PREFETCH
        // Prefetch without predicting
        prefetch_file(fd);
#endif

        return ret;
}


int posix_fadvise(int fd, off_t offset, off_t len, int advice){
        int ret = 0;

        debug_printf("%s: called for %d, ADV=%d\n", __func__, fd, advice);

#ifdef DISABLE_FADV_RANDOM
        if(advice == POSIX_FADV_RANDOM)
                goto exit;
#endif
        ret = real_posix_fadvise(fd, offset, len, advice);
exit:
        return ret;
}


ssize_t pread(int fd, void *data, size_t size, off_t offset){

        ssize_t amount_read;

#ifdef PREDICTOR
        file_predictor *fp = fd_to_file_pred[fd];
        if(fp){
                fp->predictor_update(offset, size);
                if((fp->is_sequential() >= LIKELYSEQ) && !fp->already_prefetched){
                        //if(!fp->already_prefetched){
                        prefetch_file(fd, fp);
                        fp->already_prefetched = true;
                }
                }
#endif

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


/*
   size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream){

//debug_printf("%s: TID:%ld\n", __func__, gettid());
size_t pfetch_size = 0;
size_t amount_read = 0;

amount_read = real_fread(ptr, size, nmemb, stream);
return amount_read;


#ifdef SEQ_PREFETCH
amount_read = fread_ra(ptr, size, nmemb, stream, NR_RA_PAGES*PAGESIZE);
#else
amount_read = real_fread(ptr, size, nmemb, stream);
#endif

exit:
return amount_read;
}
*/


void handle_file_close(int fd){
#ifdef PREDICTOR
        file_predictor *fp = fd_to_file_pred[fd];
        if(fp){
                delete(fp);
        }
#endif
exit:
        return;
}


int fclose(FILE *stream){
        int fd = fileno(stream);
        handle_file_close(fd);
        return real_fclose(stream);
}


int close(int fd){
        handle_file_close(fd);
        return real_close(fd);
}


ssize_t readahead(int fd, off_t offset, size_t count){
        ssize_t ret = 0;

#ifdef DISABLE_APP_READAHEADS
        goto exit;
#endif

        ret = real_readahead(fd, offset, count);

exit:
        return ret;
}
