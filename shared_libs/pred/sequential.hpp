#ifndef _SEQUENTIAL_HPP
#define _SEQUENTIAL_HPP

#include <bits/stdc++.h>
#include <fstream>
#include <string>
#include "util.hpp"
#define LENGTH 10 //should be > 2

struct stride_dat{
    off_t stride;
    size_t bytes; //Bytes accessed
};

class sequential{
    public:
        std::unordered_map<int, struct stride_dat> strides;
        std::unordered_map<int, std::deque<struct pos_bytes>> current_stream;

        bool is_sequential(int fd); //True if sequential
        int is_strided(int fd); //True if strided

        void insert(struct pos_bytes);
        void remove(int fd);
        void print_all_strides();

        void init_stride(int fd);
        off_t get_stride(int fd);
        void update_stride(int fd);
        bool exists(int fd); // checks if this fd is in the structures
};

#endif
