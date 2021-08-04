#ifndef _SEQUENTIAL_HPP
#define _SEQUENTIAL_HPP

#include <bits/stdc++.h>
#include <limits.h>
#include <bev/linear_ringbuffer.hpp>

#include "worker.hpp"

#include "robin_hood.h"

#define HISTORY 5 // Number of past accesses considered >2
#define SEQ_ACCESS 0 //Sequential access stride=0

#define DEFNSEQ (-8) //Not seq or strided(since off_t is ulong)
#define LIKELYNSEQ (-4) /*possibly not seq */
#define POSSNSEQ 0 /*possibly not seq */
#define MAYBESEQ 1 /*maybe seq */
#define POSSSEQ 2 /* possibly seq? */
#define LIKELYSEQ 4 /* likely seq? */
#define DEFSEQ 8 /* definitely seq */


struct stride_dat{
    long stride;
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
	robin_hood::unordered_node_map<int, long> fd_access_map;

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

	int update_seq_likelyness(int fd, int val);
	void init_seq_likelyness(int fd);

	long get_seq_likelyness(int fd); /*likelyness of being sequential */

	bool is_definitely_seq(int fd);
	bool is_definitely_notseq(int fd);

};


void infinite_loop(void* num);
size_t seq_prefetch(struct pos_bytes curr_access, long stride);
void __seq_prefetch(void *pfetch_info);
//XXX:To implement seq_relinquish
bool seq_relinquish(struct pos_bytes curr_access, long stride);

//Prefetch or not?
int prefetch_now(void *pfetch_info);


#endif
