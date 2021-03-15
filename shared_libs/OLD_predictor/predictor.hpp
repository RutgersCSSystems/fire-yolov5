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

#include "ngram.hpp"

#define SEQ_CHANGE 0.1 //Change values based on seq observation
#define RAND_CHANGE 0.4 //Change values based on random observation

#define TOL 0.1 //Tolerance from 0 to call there is no file read 

bool firsttime = true;

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
extern std::deque <struct pos_bytes> track; //This keeps track of the last GRAMS accesses

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
