#ifndef _SEQUENTIAL_HPP
#define _SEQUENTIAL_HPP

#include <bits/stdc++.h>
#include <fstream>
#include <string>
#include "util.hpp"
#define LENGTH 5

struct stride{
    off_t stride;
};

class sequential{
	public:
         std::unordered_map<int, struct stride> strides;
         std::unordered_map<int, std::deque<struct pos_bytes>> current_stream;

        void insert(struct pos_bytes);
        void remove_access(int fd);
        void print_all_strides();
        off_t get_stride(int fd);
        void update_stride(int fd);
        bool exists(int fd); // checks if this fd is in the structures
};

#endif
