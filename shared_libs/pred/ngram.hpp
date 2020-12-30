#include <bits/stdc++.h>
#include<fstream>
#include<string>
#include "util.hpp"
#define GRAMS 2 //length of n-gram

/*struct pos_bytes{
    int fd; //fd number
    off_t pos; //last file seek position
    size_t bytes; //size of access
};*/

class ngram{
    public:
        /*
         * Map of Map MOM
         */
        std::unordered_map<std::string, std::unordered_map<std::string, int>> past_freq; //MOM
        std::deque <struct pos_bytes> current_stream; //keeps the current Length of accesses

        int insert_to_ngram(struct pos_bytes access);
        void print_ngram();
        std::string get_max_freq_access(std::string first_key); //ret access with max freq
};

std::string convert_to_string(std::deque<struct pos_bytes> stream, int start, int length);
std::deque<struct pos_bytes> string_to_deque(std::string input);
