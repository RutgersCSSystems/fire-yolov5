#define _GNU_SOURCE
#include <stdio.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <stdbool.h>

#include "../utils/bitarray.h"
#include "../util.hpp"

#define __READAHEAD_INFO 451

#define PAGES 5000

long readahead_info(int fd, loff_t offset, size_t count, struct read_ra_req *ra_req)
{
        return syscall(__READAHEAD_INFO, fd, offset, count, ra_req);
}

int main()
{
        struct read_ra_req ra;
        off_t file_pos = 0;

        off_t file_size = 1 * GB;

        off_t start_pg; //start from here in page_cache_state
        off_t zero_pg; //first zero bit found here
        off_t pg_diff;

        int fd = open("bigfakefile.txt", O_RDWR);

        bit_array_t *page_cache_state = NULL;
        page_cache_state = BitArrayCreate(NR_BITS_PREALLOC_PC_STATE);
        BitArrayClearAll(page_cache_state);

        ra.data = page_cache_state->array;

        if(readahead_info(fd, file_pos, (PAGES * PAGESIZE), &ra) < 0)
        {
                printf("error while readahead_info\n");
        }
        page_cache_state->array = (unsigned long*)ra.data;
        start_pg = file_pos >> PAGE_SHIFT;
        zero_pg = start_pg;
        while((zero_pg << PAGE_SHIFT) < file_size){
                if(!BitArrayTestBit(page_cache_state, zero_pg))
                {
                        break;
                }
                zero_pg += 1;
        }
        pg_diff = zero_pg - start_pg;
        printf("%s: pg_diff=%ld, fd=%d\n", __func__, pg_diff, fd);

        return 0;
}
