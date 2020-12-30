#ifndef _UTIL_HPP
#define _UTIL_HPP

#define MEMINFO "/proc/meminfo"

struct pos_bytes{
	int fd; //file descriptor
	off_t pos; //last File seek position
	size_t bytes; //size of read/write the last time
};

float get_mem_pressure();

#endif
