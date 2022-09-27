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
#include <sys/sysinfo.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <sys/resource.h>

//#include "util.hpp"
//#include "frontend.hpp"


#define __FADVISE 221


#include "utils/hashtable.h"
#include "utils/lrucache.hpp"

#ifdef MAINTAIN_UINODE
#include "uinode.hpp"


int fadvise(int fd, off_t offset, off_t len, int advice){
        return syscall(__FADVISE, fd, offset, len, advice);
}

//std::unordered_map<int, void *> inode_map;
//robin_hood::unordered_map<int, void *> inode_map;
std::atomic_flag inode_map_init;
std::mutex m;


/*****************************************************************************/
struct key
{
    uint32_t inode;
};

struct value
{
    void *value;
};

DEFINE_HASHTABLE_INSERT(insert_some, struct key, struct value);
DEFINE_HASHTABLE_SEARCH(search_some, struct key, struct value);
DEFINE_HASHTABLE_REMOVE(remove_some, struct key, struct value);



static unsigned int
hashfromkey(void *ky)
{
    struct key *k = (struct key *)ky;
    return (((k->inode << 17) | (k->inode >> 15)));
}

static int
equalkeys(void *k1, void *k2)
{
    return (0 == memcmp(k1,k2,sizeof(struct key)));
}

#ifdef ENABLE_FNAME
char* get_filename(int fd) {

	std::string str = fd_to_file_name.at(fd);
	return (char *)str.c_str();
}
#endif


int hash_insert(struct hashtable *i_hash, int inode, void *value) {

	struct key *k = (struct key *)malloc(sizeof(struct key));
    if (NULL == k) {
        printf("ran out of memory allocating a key\n");
        return 1;
    }
    k->inode = inode;

    struct value *v = (struct value *)malloc(sizeof(struct value));
    v->value = value;

    if (!insert_some(i_hash,k,v))
    	return -1;

    return 0;
}

struct value *hash_get(struct hashtable *i_hash, int inode) {

	struct value *found = NULL;
	struct key *k = (struct key *)malloc(sizeof(struct key));
    if (NULL == k) {
        printf("ran out of memory allocating a key\n");
        return NULL;
    }
    k->inode = inode;

	if (NULL == (found = search_some(i_hash, k))) {
		//printf("BUG: key not found\n");
		return NULL;
	}
	/* We don't the structure anymore */
	free(k);
	return found;
}

int hash_remove(struct hashtable *i_hash, int inode) {

	struct value *found = NULL;

	if(!i_hash)
		return -1;

	struct key *k = (struct key *)malloc(sizeof(struct key));
    if (NULL == k) {
        printf("ran out of memory allocating a key\n");
        return -1;
    }
    k->inode = inode;

	if (NULL == (found = remove_some(i_hash,k))) {
		//printf("BUG: key not found\n");
		return -1;
	}
	/* We don't the structure anymore */
	free(k);
	return 0;
}


void uinode_bitmap_lock(struct u_inode *uinode) {

	if(uinode != NULL)
		uinode->bitmap_lock.lock();
}


void uinode_bitmap_unlock(struct u_inode *uinode) {

	if(uinode != NULL)
		uinode->bitmap_lock.unlock();
}


struct u_inode *get_uinode(struct hashtable *i_hash, int fd){

	struct stat file_stat;
	int inode, ret;
	struct u_inode *uinode = NULL;
	struct value *found = NULL;

	if(!i_hash)
		return NULL;

	ret = fstat (fd, &file_stat);
	inode = file_stat.st_ino;  // inode now contains inode number of the file with descriptor fd

    //m.lock();
	//uinode = (struct u_inode *)inode_map[inode];
    found = hash_get(i_hash, inode);
    if(!found) {
    	return NULL;
    }
    uinode = (struct u_inode *)found->value;
	//m.unlock();
	return uinode;
}


#ifdef ENABLE_FNAME
int add_fd_to_inode(struct hashtable *i_map, int fd, char *fname){
#else
int add_fd_to_inode(struct hashtable *i_map, int fd){
#endif

   struct stat file_stat;
   int inode, ret;
   struct u_inode *uinode = NULL;
   struct value *found = NULL;

   bool new_uinode = false;

   if(!i_map)
	return -1;

    ret = fstat (fd, &file_stat);
    inode = file_stat.st_ino;  // inode now contains inode number of the file with descriptor fd

    m.lock();

    found = hash_get(i_map, inode);
    if(found) {
    	uinode = (struct u_inode *)found->value;
    }
	if(uinode == NULL){
                uinode = new struct u_inode;
		if(!uinode){
			m.unlock();
			return -1;
		}
                new_uinode = true;
		uinode->ino = inode;
		uinode->fdcount = 0;
		uinode->full_prefetched = 0;

                uinode->file_size = file_stat.st_size;

#if defined(READAHEAD_INFO_PC_STATE) && defined(PER_INODE_BITMAP)
       /*
       * Allocate per inode bitmaps if adding new inode
       */
		uinode->page_cache_state = BitArrayCreate(NR_BITS_PREALLOC_PC_STATE);
        BitArrayClearAll(uinode->page_cache_state);
        printf("%s: adding page cache to uinode %d with %u bits\n",
        		__func__, inode, NR_BITS_PREALLOC_PC_STATE);
#else
                uinode->page_cache_state = NULL;
#endif

#ifdef ENABLE_FNAME
		strcpy(uinode->filename, fname);
#endif
		hash_insert(i_map, inode, (void *)uinode);
	}
	m.unlock();
	uinode->fdlist[uinode->fdcount] = fd;
	uinode->fdcount++;
	debug_printf("ADDING INODE %d, FDCOUNT %d, uinode=%p \n", inode, uinode->fdcount, uinode);

#ifdef ENABLE_EVICTION
        //Adds the uinode to the LRU
        if(new_uinode && uinode && uinode->file_size > MIN_FILE_SZ){
                update_lru(uinode);
        }
#endif

	return 0;
}


void remove_fd_from_uinode(struct u_inode *uinode, int fd){

	int newfdlist[MAX_FD_PER_INODE];
	int new_i = 0;

	for(int i=0; i<MAX_FD_PER_INODE; i++){
		if(uinode->fdlist[i] == fd){
			uinode->fdlist[i] = 0;
		}

		if(uinode->fdlist[i] >= 3){
			newfdlist[new_i] = uinode->fdlist[i];
			new_i += 1;
		}
	}

	for(int i=0; i<MAX_FD_PER_INODE; i++){
		uinode->fdlist[i] = newfdlist[i];
	}
}


bool is_file_closed(struct u_inode *uinode, int fd){
	if(!uinode)
		return false;

	for(int i=0; i<MAX_FD_PER_INODE; i++){
		if(uinode->fdlist[i] == fd){
			return false;
		}
	}
	return true;
}


/*
 * Reduce and remove inode refcount because a file descriptor
 * might have been close.
 */
int inode_reduce_ref(struct hashtable *i_map, int fd) {

	struct u_inode *uinode = NULL;

	if(!i_map)
		return -1;

	uinode = get_uinode(i_map, fd);
	if(uinode && uinode->fdcount > 0) {
		remove_fd_from_uinode(uinode, fd);

		uinode->fdcount--;
		return uinode->fdcount;
	}
	return -1;
}

struct hashtable *init_inode_fd_map(void) {
	 return create_hashtable(MAXFILES, hashfromkey, equalkeys);
}


int handle_close(struct hashtable *i_map, int fd){

	int inode_fd_count = -1;

	if(!i_map)
		return -1;
	/*
	 * if the reference count is 0,
	 * FIXME: also remove the software uinode? But that would
	 * require protection
	 */
	inode_fd_count = inode_reduce_ref(i_map, fd);
	//printf("%s:%d Reducing current FDCOUNT %d\n",
		//	__func__, __LINE__, inode_fd_count);
	return inode_fd_count;
}



#ifdef ENABLE_EVICTION
/*Number of pages free inside the OS*/

/*GLOBAL FILE LEVEL LRU*/
cache::lru_cache<int, struct u_inode*> lrucache(MAXFILES);
std::mutex lru_guard;

#if 0
std::atomic<long> nr_os_free_pg(0);
/*
 * Update the number of free pages in OS
 */
void update_nr_free_pg(unsigned long nr_free){
        nr_os_free_pg.store(nr_free);
}

void increase_free_pg(unsigned long increased_pg){
        nr_os_free_pg += increased_pg;
}
#endif


void update_lru(struct u_inode *uinode){
        if(uinode){
                std::lock_guard<std::mutex> guard(lru_guard);
                lrucache.put(uinode->ino, uinode);
        }
}


struct u_inode *get_lru_victim(){
        std::lock_guard<std::mutex> guard(lru_guard);
        return lrucache.pop_last()->second;
}

/*
long curr_available_free_mem_pg(){
        return nr_os_free_pg.load();
}
*/

/*
 * Returns True if available memory is lower than
 * LOW WATERMARK
 */
unsigned long mem_low_watermark(){
        struct sysinfo si;
        sysinfo (&si);

        return (si.freeram <= MEM_LOW_WATERMARK);
}


/*
 * Returns True if available memory is higher than
 * HIGH WATERMARK
 */
unsigned long mem_high_watermark(){
        struct sysinfo si;
        sysinfo (&si);

        return (si.freeram > MEM_HIGH_WATERMARK);
        //return (nr_os_free_pg.load() > (MEM_HIGH_WATERMARK >> PAGE_SHIFT));
}


/*
 * Call this for victim uinode
 */
int evict_inode_from_mem(struct u_inode *uinode){

        if(!uinode)
                return -1;

        if((uinode->fdcount > 0)
                && (uinode->file_size > 0)
                && (uinode->fdlist[0] > 0)
                && (uinode->evicted != FILE_EVICTED))
        {

                if(fadvise(uinode->fdlist[0], 0, 0, POSIX_FADV_DONTNEED)){
                        fprintf(stderr, "%s:%d eviction failed using fadvise fd:%d SIZE:%zu\n", __func__,
                                        __LINE__, uinode->fdlist[0], uinode->file_size);
                        return -1;
                }

                debug_printf("%s: evicting uinode:%d, fd:%d\n", __func__, uinode->ino, uinode->fdlist[0]);

                uinode->evicted = FILE_EVICTED;
		uinode->fully_prefetched.store(false); //Reset fully prefetched for this file
                //increase_free_pg(uinode->file_size >> PAGE_SHIFT);
        }

        return 0;
}


//EVICTION CODE
void evict_inactive_inodes(void *arg){

        struct hashtable *i_map = (struct hashtable *)arg;
        int tot_inodes;

        //off_t curr_mem_gb = 0;

        while(true){
retry:
                tot_inodes = hashtable_count(i_map);

                if(tot_inodes < 2 || !lrucache.size()){
                        goto wait_for_eviction;
                }

                if(!mem_low_watermark()){
                        goto wait_for_eviction;
                }

                evict_inode_from_mem(get_lru_victim());

                //Not enough eviction done
                if(!mem_high_watermark()){
                        goto retry;
                }

wait_for_eviction:
                sleep(SLEEP_TIME);
        }
}
#endif //ENABLE_EVICTION

#endif //MAINTAIN_UINODE


#ifdef ENABLE_MPI
struct hashtable *init_mpifile_fd_map(void) {
	 return create_hashtable(MAXFILES, hashfromkey, equalkeys);
}
#endif
