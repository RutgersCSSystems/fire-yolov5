#define _GNU_SOURCE
//#define _XOPEN_SOURCE 600

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

//This is defined for each file descriptor
typedef struct probability_cartesian{
	off_t pos; //last File seek position
	size_t bytes; //size of read/write the last time
	float read;  // [0, 1]: 0->Random Reads, 1 -> Seq Reads
	float write; // [0, 1]: 0->Random Writes, 1 -> Seq Writes
}prob_cart;

std::map<int, prob_cart> predictor; //This has characterstic of each file

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


///////////////////////////////////
//Predictor Functions

//This function inserts a new file in the map
void init(int fd, off_t pos, size_t size) 
{
	prob_cart init_pc;
	init_pc.read = 0; //Random read
	init_pc.write = 0; //Random read
	init_pc.pos = pos; //file init position
	init_pc.bytes = size; //Bytes read/write 
	
	predictor.insert(std::pair<int, prob_cart>(fd, init_pc));
}

void update_read_predictor(int fd, off_t pos, size_t size)
{
	std::map<int, prob_cart>::iterator iter = predictor.find(fd);

	if(iter == predictor.end()) //new file
		init(fd, pos, size);


}

void update_write_predictor(int fd, off_t pos, size_t size)
{
	//TODO
}


void remove(int fd) //removes the fd
{
	std::map<int, prob_cart>::iterator iter = predictor.find(fd);
	predictor.erase(iter);
}

///////////////////////////////////

int fclose(FILE *stream){
	//call fadvise
	int fd = fileno(stream);
	//printf("File %d fadvise running\n", fd);
	posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);

	return real_fclose(stream);
}

int close(int fd){
	//printf("File close detected\n");
	return real_close(fd);
}

size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){


	size_t amount_written;

	// Perform the actual system call
	amount_written = real_fwrite(ptr, size, nmemb, stream);

	//printf("fwrite Detected\n");

	int fd = fileno(stream);
	off_t pos = lseek(fd, 0, SEEK_CUR);
	if(pos != -1)
	{
		//printf("fd: %d, pos: %ld\n", fd, pos);
		posix_fadvise(fd, pos, size/2, POSIX_FADV_DONTNEED);
	}

	// Behave just like the regular syscall would
	return amount_written;
}

ssize_t write(int fd, const void *data, size_t size) {

	ssize_t amount_written;

	printf("write Detected \n");
	// Perform the actual system call
	amount_written = real_write(fd, data, size);

	off_t pos = lseek(fd, 0, SEEK_CUR);
	if(pos != -1)
	{
		//printf("fd: %d, pos: %ld\n", fd, pos);
		posix_fadvise(fd, pos, size/2, POSIX_FADV_DONTNEED);
	}
	//posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);

	// Behave just like the regular syscall would
	return amount_written;
}

size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream){
	size_t amount_read;

	// Perform the actual system call
	amount_read = real_fread(ptr, size, nmemb, stream);

	//printf("fread Detected\n");
	int fd = fileno(stream);
	//posix_fadvise(fd, 0, 0, POSIX_FADV_WILLNEED);

	// Behave just like the regular syscall would
	return amount_read;
}

ssize_t read(int fd, void *data, size_t size) {
	ssize_t amount_read;

	// Perform the actual system call
	amount_read = real_read(fd, data, size);

	//printf("read Detected\n");
	//posix_fadvise(fd, 0, 0, POSIX_FADV_WILLNEED);

	// Behave just like the regular syscall would
	return amount_read;
}
