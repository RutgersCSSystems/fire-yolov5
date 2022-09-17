#ifndef _UINODE_HPP
#define _UINODE_HPP

#include <mutex>
#include "util.hpp"
#include "utils/hashtable.h"
#include "utils/thpool.h"
#include "utils/bitarray.h"

//user-level inodes
struct u_inode {
	int ino; //opened file fd
	long file_size; //total filesize
	int fdlist[MAX_FD_PER_INODE]; //array of file descriptors for this inode
	int fdcount; //total fd's opened for this file

	int full_prefetched; //has the file been already fully prefetched?

#ifdef ENABLE_FNAME
    char filename[256];
#endif

	long prefetch_size; //size of each prefetch req
	//difference between the end of last access and start of this access in pages
	size_t stride;
	//helps debugging
	int last_fd;

	/*
	 * Send a pointer to the page cache state to be updated
	 */
	bit_array_t *page_cache_state;
        std::mutex bitmap_lock;
};

struct hashtable *init_inode_fd_map(void);

#ifdef ENABLE_MPI
struct hashtable *init_mpifile_fd_map(void) ;
#endif

int handle_close(struct hashtable *, int);
struct u_inode *get_uinode(struct hashtable *, int);

#ifdef ENABLE_FNAME
int add_fd_to_inode(struct hashtable *, int, char);
#else
int add_fd_to_inode(struct hashtable *, int fd);
#endif

void uinode_bitmap_lock(struct u_inode *inode);
void uinode_bitmap_unlock(struct u_inode *inode);

bool is_file_closed(struct u_inode *uinode, int fd);

#endif
