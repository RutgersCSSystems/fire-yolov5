#ifndef _SEQUENTIAL_HPP
#define _SEQUENTIAL_HPP

#include <bits/stdc++.h>
#include <limits.h>

#define HISTORY 5 // Number of past accesses considered >2
#define SEQ_ACCESS 0 //Sequential access stride=0
#define NOT_SEQ  (ULONG_MAX - 1) //Not seq or strided(since off_t is ulong)


struct stride_dat{
    off_t stride;
    size_t bytes; //Bytes accessed
};

class sequential{
    public:
	bool init;
        std::unordered_map<int, struct stride_dat> strides;
        std::unordered_map<int, std::deque<struct pos_bytes>> current_stream;

	sequential();     // Constructor

        bool is_sequential(int fd); //True if sequential
        off_t is_strided(int fd); //stride if strided

        void insert(struct pos_bytes);
        void remove(int fd);
        void print_all_strides();

        void init_stride(int fd);
        off_t get_stride(int fd);
        void update_stride(int fd);
        bool exists(int fd);
	//bool sane_stride(int fd);
};

bool seq_prefetch(struct pos_bytes curr_access, off_t stride);
bool __seq_prefetch(struct pos_bytes curr_access, off_t stride);
bool seq_relinquish(struct pos_bytes curr_access, off_t stride);

#endif
