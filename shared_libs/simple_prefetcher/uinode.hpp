#ifndef _UINODE_HPP
#define _UINODE_HPP


#include "shim.hpp"
#include "utils/thpool.h"
#include "utils/bitarray.h"

//user-level inodes
struct u_inode {
	int ino; //opened file fd
	long file_size; //total filesize
	int fdlist[64]; //array of file descriptors for this inode
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
};

struct u_inode *get_uinode(int fd);
#ifdef ENABLE_FNAME
int add_fd_to_inode(int fd, char *fname);
#else
int add_fd_to_inode(int fd);
#endif

#endif

