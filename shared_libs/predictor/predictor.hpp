#include <bits/stdc++.h>
#include <dlfcn.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <iostream>
#include <iterator>
#include <algorithm>
#include <map>
#include <deque>
#include <unordered_map>
#include <string>
#include <cstdlib>
#include <ctime>
#include <sys/sysinfo.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fstream>
#include <sys/syscall.h>
#include <sys/types.h>

#define MEMINFO "/proc/meminfo"


#define GRAMS 5 //Length of n-gram
#define SEQ_CHANGE 0.1 //Change values based on seq observation
#define RAND_CHANGE 0.4 //Change values based on random observation

#define TOL 0.1 //Tolerance from 0 to call there is no file read 


bool firsttime = true;

struct pos_bytes{
	int fd; //file descriptor
	off_t pos; //last File seek position
	size_t bytes; //size of read/write the last time
};

/*
//This is defined for each file descriptor
typedef struct probability_cartesian{
	std::deque <struct pos_bytes> track;
	float read;  // [-1, 1]: -1-> Rand Reads, 0->No Reads, 1 -> Seq Reads
	bool SEQ_READ; //Have given advice SEQ read
	bool WILL_NEED; //Have given advice WILL NEED
	bool RAND_READ;
	bool WONT_NEED;
}prob_cart;
*/

//std::map<int, prob_cart> predictor; //This has characterstic of each file
std::deque <struct pos_bytes> track; //This keeps track of the last GRAMS accesses
std::unordered_map<std::string, std::unordered_map<std::string, int>> predictor;
//This data structure has the following structure:
//key to top level map is the string which represents the last n accesses 
//n = {1, GRAMS}
//maps to a list of string with the following format "fd:off_t;size+fd2:off_t;size"
// Functions needed from the n-gram

void insert_and_predict_from_ngram(); //This adds the last entries 
void print_ngram(); //This prints all the entries of the ngram data structure
std::string convert_to_string(int, int);
//Also add an accuracy measure


typedef ssize_t (*real_read_t)(int, void *, size_t);
typedef size_t (*real_fread_t)(void *, size_t, size_t,FILE *);
typedef ssize_t (*real_write_t)(int, const void *, size_t);
typedef size_t (*real_fwrite_t)(const void *, size_t, size_t,FILE *);
typedef int (*real_fclose_t)(FILE *);
typedef int (*real_close_t)(int);

size_t real_fclose(FILE *stream){
	return ((real_fclose_t)dlsym(RTLD_NEXT, "fclose"))(stream);
}
size_t real_close(int fd){
	return ((real_close_t)dlsym(RTLD_NEXT, "close"))(fd);
}
size_t real_fread(void *ptr, size_t size, size_t nmemb, FILE *stream){
	return ((real_fread_t)dlsym(RTLD_NEXT, "fread"))(ptr, size, nmemb, stream);
}
size_t real_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){
	return ((real_fwrite_t)dlsym(RTLD_NEXT, "fwrite"))(ptr, size, nmemb, stream);
}
ssize_t real_write(int fd, const void *data, size_t size) {
	return ((real_write_t)dlsym(RTLD_NEXT, "write"))(fd, data, size);
}
ssize_t real_read(int fd, void *data, size_t size) {
	return ((real_read_t)dlsym(RTLD_NEXT, "read"))(fd, data, size);
}

void print_ngram()
{
	std::cout << "PRINT NGRAM" << std::endl;
	//print the complete NGRAM
	auto top_iter = predictor.begin();
	while (top_iter != predictor.end())
	{
		std::cout << "Request_string = " << top_iter->first << std::endl;
		auto second_map = top_iter->second;

		auto second_iter = second_map.begin();
		while(second_iter != second_map.end())
		{
			std::cout << second_iter->first << ": " << second_iter->second << std::endl;
			*second_iter ++;
		}
		*top_iter ++;

	}
	std::cout << "END PRINT NGRAM" << std::endl;
}


// returns the pressure on memory
// values [0, 1]: 0->No pressure, 1->High pressure on mem
// High pressure means that there is lesser free mem for programs
float get_mem_pressure(){
	std::string token;
	std::ifstream file(MEMINFO);
	unsigned long totmem, freemem;
	int gotvals = 0;
	while(file >> token) {
		if(token == "MemTotal:") 
		{
			file >> totmem;
			gotvals += 1;
		}
		else if(token == "MemAvailable:")
		{
			file >> freemem;
			gotvals += 1;
		}
		if(gotvals == 2)
			break;
	}
	return (float)(totmem-freemem) /totmem;
}

std::string convert_to_string(int start, int length)
{
	std::string a;
	if(track.size() < length)
		return "";

	std::deque <struct pos_bytes>::iterator dqiter = track.begin() + start;
	
	for(int i=start; i<start+length; i++)
	{
		if(dqiter == track.end())
			return "";

		a += std::to_string(dqiter->fd) + ",";
		a += std::to_string(dqiter->pos) + ",";
		a += std::to_string(dqiter->bytes) + "+";

		*dqiter++;
	}
	return a;
}

void insert_and_predict_from_ngram()
{
	std::deque <struct pos_bytes>::iterator dqiter = track.begin();
	if(dqiter == track.end())
		return;

	for(int i=GRAMS; i>=1; i--) //insert 1 to N gram entries in the predictor
	{
		printf("i = %d\n", i);
		std::string key = convert_to_string(0, i);

		std::unordered_map<std::string,std::unordered_map<std::string, int>>::const_iterator got = predictor.find(key);

		std::string nextread = convert_to_string(i, 1);

		if(got == predictor.end()) //will need to insert
		{
			std::unordered_map<std::string, int> a;
			a[nextread] = 1; //freq = 1
			predictor[key] = a;
		}
		else
		{
			auto second_map = got->second; //<string,int>map
			int freq = second_map[nextread] += 1;

			std::cout << "freq: " << freq << std::endl;

		}

	}
	//print_ngram();
	return ;
}
