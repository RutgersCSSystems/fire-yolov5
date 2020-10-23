#define _GNU_SOURCE
//#define _XOPEN_SOURCE 600

#include "cfun.hpp"

///////////////////////////////////
//Predictor Functions

//This function inserts a new file in the map
void init(int fd, off_t pos, size_t size) 
{
	prob_cart init_pc;
	init_pc.read = 0; //Random read
	//init_pc.write = 0; //Random read

	struct pos_bytes pb;
	pb.pos = pos; //file init position
	pb.bytes = size; //Bytes read/write 

	init_pc.track.push_back(pb);
	
	predictor.insert(std::pair<int, prob_cart>(fd, init_pc));
}

//predicts read behaviour per file and gives appropriate probabilistic advice
void read_predictor(int fd, off_t pos, size_t size)
{
	if(firsttime)
	{
		std::srand(std::time(NULL));
		firsttime = false;
	}

	std::map<int, prob_cart>::iterator iter = predictor.find(fd);

	if(iter == predictor.end()) //new file
	{
		init(fd, pos, size);
		return;
	}

	//check the last reads and see if they match this 
	//change the values based 

	struct pos_bytes pb;
	pb.pos = pos;
	pb.bytes = size;

	iter->second.track.push_back(pb);

	if(iter->second.track.size() > SPEED)
	{
		iter->second.track.pop_front();

		//update the read probability values
		//TODO

		//for each pair of reads, check if the second off_t is > first off_t
		// add CHANGE/SPEED else deduct the same

		std::deque <struct pos_bytes>::iterator dqit = iter->second.track.begin();
		
		while(dqit != iter->second.track.end())
		{

		}
		//iter->second.read //FIXME
	}

	
	//toss a biased coin and call fadv based on it
	float rand = (100.0 * std::rand() / (RAND_MAX + 1.0)) + 1; //[1, 100]
	
	if(rand <= 100.0*iter->second.read)
	{
		posix_fadvise(fd, 0, 0, POSIX_FADV_SEQUENTIAL);
	}
	
	return;
}


//predicts write behaviour per file and gives appropriate probabilistic advice
void write_predictor(int fd, off_t pos, size_t size)
{
	//TODO
}


void remove(int fd) //removes the fd
{
	posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
	std::map<int, prob_cart>::iterator iter = predictor.find(fd);
	predictor.erase(iter);
}

///////////////////////////////////

///////////////////////////////////
//Overloaded functions
///////////////////////////////////


int fclose(FILE *stream){
	//call fadvise
	int fd = fileno(stream);
	//printf("File %d fadvise running\n", fd);
	remove(fd);
	//posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);

	return real_fclose(stream);
}


int close(int fd){
	//printf("File close detected\n");
	remove(fd);
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
	off_t pos = lseek(fd, 0, SEEK_CUR);
	if(pos != -1 && fd != -1)
	{
		read_predictor(fd, pos, size*nmemb);
	}


	//posix_fadvise(fd, 0, 0, POSIX_FADV_WILLNEED);

	// Behave just like the regular syscall would
	return amount_read;
}


ssize_t read(int fd, void *data, size_t size) {
	ssize_t amount_read;

	// Perform the actual system call
	amount_read = real_read(fd, data, size);

	off_t pos = lseek(fd, 0, SEEK_CUR);
	if(pos != -1)
	{
		read_predictor(fd, pos, size);
	}
	
	//posix_fadvise(fd, 0, 0, POSIX_FADV_WILLNEED);

	// Behave just like the regular syscall would
	return amount_read;
}

///////////////////////////////
