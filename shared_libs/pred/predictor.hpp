struct pos_bytes{
	int fd; //file descriptor
	off_t pos; //File seek position
	size_t bytes; //size of read/write
};

int handle_read(int fd, off_t pos, size_t bytes);
int handle_write(int fd, off_t pos, size_t bytes);
int handle_close(int fd);
int handle_open(int fd);
