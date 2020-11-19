//#define _GNU_SOURCE
//#define _XOPEN_SOURCE 600

#include "predictor.hpp"


/*
//This function inserts a new file in the map
void init(int fd, off_t pos, size_t size) 
{
	prob_cart init_pc;
	init_pc.read = 0; //Random read
	init_pc.SEQ_READ = false;
	init_pc.WILL_NEED = false;
	init_pc.RAND_READ = false;
	init_pc.WONT_NEED = false;

	struct pos_bytes pb;
	pb.pos = pos; //file init position
	pb.bytes = size; //Bytes read/write 

	init_pc.track.push_back(pb);

	predictor.insert(std::pair<int, prob_cart>(fd, init_pc));
}
*/

//predicts read behaviour per file and gives appropriate probabilistic advice
void read_predictor(int fd, off_t pos, size_t size)
{
	printf("Reads\n");
	if(firsttime)
	{
		std::srand(std::time(NULL));
		firsttime = false;
	}

	//Add new values to the queue
	struct pos_bytes pb;
	pb.fd = fd;
	pb.pos = pos;
	pb.bytes = size;

	push_latest_req(pb);

	if(latest_req_size() >= GRAMS+1)
	{
		insert_to_ngram();

		remove_oldest_req();
	}


	/* DECISION BAAD ME
	//toss a biased coin and call fadv based on it
	float rand = (100.0 * std::rand() / (RAND_MAX + 1.0)) + 1; //[1, 100]

	if(iter->second.read > 0) //Towards sequential
	{
		if(rand <= 100.0*iter->second.read) //Bias towards seq reads
		{
			//will reduce multiple sys call overheads
			if(!iter->second.WILL_NEED)
			{
				posix_fadvise(fd, 0, 0, POSIX_FADV_WILLNEED);
				iter->second.WILL_NEED = true;
			}
#ifdef DEBUG
			printf("WILL NEED, read=%f, rand=%f\n", iter->second.read, rand);
#endif
		}
		else
		{
			//will reduce multiple sys call overheads
			if(!iter->second.SEQ_READ)
			{
				posix_fadvise(fd, 0, 0, POSIX_FADV_SEQUENTIAL);
				iter->second.SEQ_READ = true;
				iter->second.RAND_READ = false; 
			}
#ifdef DEBUG
			printf("SEQ read=%f, rand=%f\n", iter->second.read, rand);
#endif
		}
	}
	else if(iter->second.read < 0) //Towards random reads
	{
		//float mempressure = get_mem_pressure();
		if(rand <= 100.0*get_mem_pressure()) //higher the pressure on mem
		{
			posix_fadvise(fd, pos, size, POSIX_FADV_DONTNEED);
			iter->second.WILL_NEED = false;
#ifdef DEBUG
			printf("DONTNEED read=%f, rand=%f\n", iter->second.read, rand);
#endif
		}
		else
		{
			//will reduce multiple sys call overheads
			if(!iter->second.RAND_READ)
			{
				posix_fadvise(fd, 0, 0, POSIX_FADV_RANDOM);
				iter->second.SEQ_READ = false;
				iter->second.RAND_READ = true;
			}
#ifdef DEBUG
			printf("RANDOM read=%f, rand=%f\n", iter->second.read, rand);
#endif
		}
	}
*/
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

	/*
	std::map<int, prob_cart>::iterator iter = predictor.find(fd);

	float read_prob;

	if(iter == predictor.end()) //new file
	{
		read_prob = 0;
		init(fd, 0, 0);
		return;
	}
	else
		read_prob = iter->second.read;

	//Toss a coin
	float rand = (100.0 * std::rand() / (RAND_MAX + 1.0)) + 1; //[1, 100]

#ifdef DEBUG
	printf("DONTNEED pressure=%f, rand=%f, read=%f\n", get_mem_pressure(), rand, read_prob);
#endif

	//FIXME TEMP if(read_prob <= TOL && read_prob >= -TOL) //No reads within tolerance
	{
		if(rand <= 100.0*get_mem_pressure())
		{
			posix_fadvise(fd, pos, size, POSIX_FADV_DONTNEED);
		}
	}
	*/
	return;
}


void remove(int fd) //removes the fd
{
	posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
#ifdef DEBUG
	printf("DONTNEED\n");
#endif
	/*
	std::map<int, prob_cart>::iterator iter = predictor.find(fd);
	if(iter != predictor.end())
		predictor.erase(iter);
		*/
	return;
}


//Print simple access pattern 
void access_pattern(int fd, off_t pos, size_t size, int type)
{
	//pid_t tid = syscall(SYS_gettid);
	pid_t pid = getpid();
	struct stat sb;
	if(fstat(fd, &sb) == 0)
	{
		switch (sb.st_mode & S_IFMT) {
			case S_IFBLK:  printf("block device");            break;
			case S_IFCHR:  printf("character device");        break;
			case S_IFDIR:  printf("directory");               break;
			case S_IFIFO:  printf("FIFO/pipe");               break;
			case S_IFLNK:  printf("symlink");                 break;
			case S_IFREG:  printf("regular file");            break;
			case S_IFSOCK: printf("socket");                  break;
			default:       printf("unknown?");                break;
		}

	}

	if(type == 0)
		printf(" read, pid:%d, fd: %d, Pos: %ld, size: %lu\n", pid, fd, pos, size);

	if(type == 1)
		printf(" write, pid:%d, fd: %d, Pos: %ld, size: %lu\n", pid, fd, pos, size);
}

///////////////////////////////////


int fclose(FILE *stream){
#ifdef DEBUG
	printf("fclose detected\n");
#endif
	//call fadvise
#ifdef PREDICTOR
	int fd = fileno(stream);
	if(fd > 2)
		remove(fd);
#endif

	return real_fclose(stream);
}


int close(int fd){
#ifdef DEBUG
	printf("File close detected\n");
#endif

#ifdef PREDICTOR
	if(fd > 2)
		remove(fd);
#endif
	return real_close(fd);
}


size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream){

	struct stat st;
	size_t amount_written;

	// Perform the actual system call
	amount_written = real_fwrite(ptr, size, nmemb, stream);

	int fd = fileno(stream);
	off_t pos = -1;


	if(fstat(fd, &st) == 0)
	{
		if(S_ISREG(st.st_mode))
		{
			pos = lseek(fd, 0, SEEK_CUR);
			if(pos != -1 && fd > 2)
			{

#ifdef PREDICTOR
				write_predictor(fd, pos, size*nmemb);
#endif
			}
		}
	}
#ifdef PATTERN
				access_pattern(fd, pos, size*nmemb, 1);
#endif

	return amount_written;
}


ssize_t write(int fd, const void *data, size_t size) {

#ifdef DEBUG
	printf("writes\n");
#endif

	ssize_t amount_written;
	struct stat st;

	// Perform the actual system call
	amount_written = real_write(fd, data, size);
	off_t pos = -1;

	if(fstat(fd, &st) == 0)
	{
		if(S_ISREG(st.st_mode))
		{
			pos = lseek(fd, 0, SEEK_CUR);
			if(pos != -1 && fd > 2)
			{

#ifdef PREDICTOR
				write_predictor(fd, pos, size);
#endif
			}
		}
	}
#ifdef PATTERN
				access_pattern(fd, pos, size, 1);
#endif

	return amount_written;
}


size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream){

	struct stat st;
	size_t amount_read;

	// Perform the actual system call
	amount_read = real_fread(ptr, size, nmemb, stream);

	int fd = fileno(stream);
	off_t pos = -1;

	if(fstat(fd, &st) == 0)
	{
		if(S_ISREG(st.st_mode))
		{
			off_t pos = lseek(fd, 0, SEEK_CUR);
			if(pos != -1 && fd > 0)
			{

#ifdef PREDICTOR
				read_predictor(fd, pos, size*nmemb);
#endif
			}
		}
	}
#ifdef PATTERN
				access_pattern(fd, pos, size*nmemb, 0);
#endif

	return amount_read;
}


ssize_t read(int fd, void *data, size_t size) {

	struct stat st;
	ssize_t amount_read;


	// Perform the actual system call
	amount_read = real_read(fd, data, size);
	off_t pos = -1;

	if(fstat(fd, &st) == 0)
	{
		if(S_ISREG(st.st_mode))
		{
			off_t pos = lseek(fd, 0, SEEK_CUR);
			if(pos != -1 && fd > 0)
			{

#ifdef PREDICTOR
				read_predictor(fd, pos, size);
#endif
			}
		}
	}
#ifdef PATTERN
				access_pattern(fd, pos, size, 0);
#endif
	return amount_read;
}

///////////////////////////////
