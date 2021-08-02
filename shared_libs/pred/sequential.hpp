#ifndef _SEQUENTIAL_HPP
#define _SEQUENTIAL_HPP

#include <bits/stdc++.h>
#include <limits.h>
#include <bev/linear_ringbuffer.hpp>

#include "worker.hpp"

#include "robin_hood.h"

#define HISTORY 5 // Number of past accesses considered >2
#define SEQ_ACCESS 0 //Sequential access stride=0
#define NOT_SEQ (ULONG_MAX - 1) //Not seq or strided(since off_t is ulong)

#define NOTLIKELY 1
#define LIKELY 2
#define DEFINITELY 3


struct stride_dat{
    off_t stride;
    size_t bytes; //Bytes accessed
};

class sequential{
    public:
	bool init;

#if 0
        std::unordered_map<int, struct stride_dat> strides;
	std::unordered_map<int, std::deque<struct pos_bytes>> current_stream;
	std::unordered_map<int, off_t> prefetch_fd_map;

#endif
#if 1	
	robin_hood::unordered_node_map<int, struct stride_dat> strides;
	robin_hood::unordered_node_map<int, std::deque<struct pos_bytes>> current_stream;
	robin_hood::unordered_node_map<int, off_t> prefetch_fd_map;
	robin_hood::unordered_node_map<int, int> fd_access_map;

#endif

        /* //This is ring buffer DataStructures
         * std::unordered_map<int, 
            bev::linear_ringbuffer_<struct pos_bytes, HISTORY>> current_stream;

        struct pos_bytes *present_hist = (struct pos_bytes*) 
            malloc(sizeof(struct pos_bytes)*HISTORY);
            */

	sequential();     // Constructor

        bool is_sequential(int fd); //True if sequential
        off_t is_strided(int fd); //stride if strided

        void insert(struct pos_bytes);
        void remove(int fd);
        void print_all_strides();

	void init_fd_maps(int fd);

        off_t get_stride(int fd);
        void update_stride(int fd);
        bool exists(int fd);
	
	off_t get_prefetch_pos(int fd);
	void insert_prefetch_pos(int fd, off_t pos);

	int prefetch_now_fd(void *pfetch_info, int fd);

	void update_seq_likelyness(int fd, int val);
	bool get_seq_likelyness(int fd);

};


void infinite_loop(void* num);
size_t seq_prefetch(struct pos_bytes curr_access, off_t stride);
void __seq_prefetch(void *pfetch_info);
//XXX:To implement seq_relinquish
bool seq_relinquish(struct pos_bytes curr_access, off_t stride);

//Prefetch or not?
int prefetch_now(void *pfetch_info);


#endif
