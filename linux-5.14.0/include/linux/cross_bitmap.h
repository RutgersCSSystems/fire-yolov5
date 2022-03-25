#ifndef _LINUX_CROSS_BITMAP_H
#define _LINUX_CROSS_BITMAP_H

void *cross_test(void);

void alloc_cross_bitmap(unsigned long **bitmap, unsigned long nr_pages, 
                unsigned long nr_pg_portion);

void free_cross_bitmap(unsigned long **bitmap);

#endif
