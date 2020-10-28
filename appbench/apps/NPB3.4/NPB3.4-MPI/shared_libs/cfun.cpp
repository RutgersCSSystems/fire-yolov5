//#define _GNU_SOURCE
//#define _XOPEN_SOURCE 600

#include "cfun.hpp"

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
#ifdef DEBUG
	printf("Read predictor\n");
#endif
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

	//Add new values to the queue
	struct pos_bytes pb;
	pb.pos = pos;
	pb.bytes = size;

	iter->second.track.push_back(pb);

	if(iter->second.track.size() > SPEED)
	{
		iter->second.track.pop_front();

		//update the read probability values
		//for each pair of reads, check if the second off_t is > first off_t
		// add CHANGE/SPEED else deduct the same

		std::deque <struct pos_bytes>::iterator dqit = iter->second.track.begin();
		off_t last_pos = dqit->pos;
		*dqit++;
		while(dqit != iter->second.track.end())
		{
			if(last_pos < dqit->pos) //Sequential read
				iter->second.read += SEQ_CHANGE/SPEED;
			else if(last_pos > dqit->pos) //Random read
				iter->second.read -= RAND_CHANGE/SPEED;
			last_pos = dqit->pos;
			*dqit ++;
		}
		if(iter->second.read < -1.0) //Values reset to max 
			iter->second.read = -1.0;
		else if(iter->second.read > 1.0)
			iter->second.read = 1.0;
	}


	//toss a biased coin and call fadv based on it
	float rand = (100.0 * std::rand() / (RAND_MAX + 1.0)) + 1; //[1, 100]

	if(iter->second.read > 0) //Towards sequential
	{
		if(rand <= 100.0*iter->second.read) //Bias towards seq reads
		{
			//TODO: mechanism to remove multiple of these calls
			//add and check a bool on per file DS.
			//will reduce multiple sys call overheads
			posix_fadvise(fd, 0, 0, POSIX_FADV_WILLNEED);
		}
		else
		{
			//TODO: mechanism to remove multiple of these calls
			//add and check a bool on per file DS.
			//will reduce multiple sys call overheads
			posix_fadvise(fd, 0, 0, POSIX_FADV_SEQUENTIAL);
		}
	}
	else if(iter->second.read < 0) //Towards random reads
	{
		//float mempressure = get_mem_pressure();
		if(rand <= 100.0*get_mem_pressure()) //higher the pressure on mem
		{
			posix_fadvise(fd, pos, size, POSIX_FADV_DONTNEED);
		}
		else
		{
			//TODO: mechanism to remove multiple of these calls
			//add and check a bool on per file DS.
			//will reduce multiple sys call overheads
			posix_fadvise(fd, 0, 0, POSIX_FADV_RANDOM);
		}
	}

	return;
}


//predicts write behaviour per file and gives appropriate probabilistic advice
void write_predictor(int fd, off_t pos, size_t size)
{
#ifdef DEBUG
	printf("write predictor\n");
#endif
	if(firsttime)
	{
		std::srand(std::time(NULL));
		firsttime = false;
	}

	std::map<int, prob_cart>::iterator iter = predictor.find(fd);

	float read_prob;

	if(iter == predictor.end()) //new file -> Hasnt been read
		read_prob = 0;
	else
		read_prob = iter->second.read;

	//Toss a coin
	float rand = (100.0 * std::rand() / (RAND_MAX + 1.0)) + 1; //[1, 100]

	//TODO: check if a small limit changes things differently
	//==0 will only remain if there are no reads what soever
	if(read_prob == 0) //No reads
	{
		if(rand <= 100.0*get_mem_pressure())
		{
			posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
#ifdef DEBUG
			printf("FADV_DONTNEED\n");
#endif
		}
	}
	return;
}


void remove(int fd) //removes the fd
{
	posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
	std::map<int, prob_cart>::iterator iter = predictor.find(fd);
	if(iter != predictor.end())
		predictor.erase(iter);
	return;
}

///////////////////////////////////


int fclose(FILE *stream){
#ifdef DEBUG
	printf("fclose detected\n");
#endif
	//call fadvise
	int fd = fileno(stream);
	if(fd != -1)
		remove(fd);

	return real_fclose(stream);
}


int close(int fd){
#ifdef DEBUG
	printf("File close detected\n");
#endif
	if(fd != -1)
		remove(fd);
	return real_close(fd);
}


size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){

	//printf("fwrite Detected\n");

	size_t amount_written;

	// Perform the actual system call
	amount_written = real_fwrite(ptr, size, nmemb, stream);

	int fd = fileno(stream);
	off_t pos = lseek(fd, 0, SEEK_CUR);
	if(pos != -1 && fd != -1)
	{
		write_predictor(fd, pos, size*nmemb);
	}

	//printf("fwrite Detected\n");
	return amount_written;
}


ssize_t write(int fd, const void *data, size_t size) {

	ssize_t amount_written;

	//printf("write Detected\n");

	// Perform the actual system call
	amount_written = real_write(fd, data, size);

	off_t pos = lseek(fd, 0, SEEK_CUR);
	if(pos != -1 && fd != -1)
	{
		write_predictor(fd, pos, size);
	}

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

	return amount_read;
}


ssize_t read(int fd, void *data, size_t size) {
	ssize_t amount_read;

	//printf("read Detected\n");

	// Perform the actual system call
	amount_read = real_read(fd, data, size);

	off_t pos = lseek(fd, 0, SEEK_CUR);
	if(pos != -1 && fd != -1)
	{
		read_predictor(fd, pos, size);
	}

	return amount_read;
}

///////////////////////////////
