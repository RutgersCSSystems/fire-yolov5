#include "util.hpp"

#define GRAMS 5 //Length of n-gram


//The above data structure has the following:
//key to top level map is the string which represents the last n accesses
//n = {1, GRAMS}
//maps to a list of string with the following format "fd:off_t;size+fd2:off_t;size"

void push_latest_req(struct pos_bytes);
int latest_req_size();
void remove_oldest_req();

void insert_and_predict_from_ngram();
void insert_to_ngram(); //This adds/updates the latest entries
std::string predict_from_ngram(); //Predicts the next set of probable calls
void print_ngram(); //This prints all the entries of the ngram data structure
std::string convert_to_string(std::deque<struct pos_bytes>, int, int);
//Also add an accuracy measure
