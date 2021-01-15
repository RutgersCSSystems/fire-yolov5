#define MAX_REMOVAL_AT_ONCE (4 * 1024 * 1024)

int handle_read(int fd, off_t pos, size_t bytes);
int handle_write(int fd, off_t pos, size_t bytes);
int handle_close(int fd);
int handle_open(int fd);
