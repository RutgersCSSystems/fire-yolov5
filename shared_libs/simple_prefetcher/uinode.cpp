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

//#include "util.hpp"
//#include "frontend.hpp"

#include "utils/hashtable.h"

#ifdef MAINTAIN_UINODE
#include "uinode.hpp"


#include <mutex>
#define MAXFILES 10000

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


struct u_inode *get_uinode(struct hashtable *i_hash, int fd){

	struct stat file_stat;
	int inode, ret;
	struct u_inode *uinode = NULL;
	struct value *found = NULL;

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
int add_fd_to_inode(struct hashtable *i_hash, int fd, char *fname){
#else
int add_fd_to_inode(struct hashtable *i_hash, int fd){
#endif

	struct stat file_stat;
	int inode, ret;
	struct u_inode *uinode = NULL;
	struct value *found = NULL;

	ret = fstat (fd, &file_stat);
	inode = file_stat.st_ino;  // inode now contains inode number of the file with descriptor fd

	m.lock();

    found = hash_get(i_hash, inode);
    if(found) {
    	uinode = (struct u_inode *)found->value;
    }
	if(uinode == NULL){
		uinode = (struct u_inode *)malloc(sizeof(struct u_inode));
		if(!uinode){
			m.unlock();
			return -1;
		}
		uinode->ino = inode;
		uinode->fdcount = 0;
		uinode->full_prefetched = 0;
#ifdef ENABLE_FNAME
		strcpy(uinode->filename, fname);
#endif
		hash_insert(i_hash, inode, (void *)uinode);
	}
	m.unlock();

	uinode->fdlist[uinode->fdcount] = fd;
	uinode->fdcount++;
	//printf("ADDING INODE %d, FDCOUNT %d \n", inode, uinode->fdcount);
	return 0;
}

/*
 * Reduce and remove inode refcount because a file descriptor
 * might have been close.
 */
int inode_reduce_ref(struct hashtable *i_map, int fd) {

	struct u_inode *uinode = get_uinode(i_map, fd);
	if(uinode && uinode->fdcount > 0) {
		//printf("%s:%d Reducing current FDCOUNT %d\n",
		//		__func__, __LINE__, uinode->fdcount);
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
#endif

