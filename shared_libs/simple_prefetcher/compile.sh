#!/bin/bash

##This compile script will compile the preload libraries and install them

#OS doesnt prefetch more than 256 pages in vanilla kernel

# PREFETCH_SIZE should be greater than 64 pages else
#there will be duplicate copy_to_user in readahead_info and
# performance will go down.

#sudo apt update; sudo apt install mpich -y

PREFETCH_SIZE=1024 ##in nr of pages
NR_WORKERS=4
CROSS_BITMAP_SHIFT=38
NR_PREDICT_SAMPLE_FREQ=8
make -j$(nproc) NR_RA_PAGES=$PREFETCH_SIZE NR_WORKERS=$NR_WORKERS CROSS_BITMAP_SHIFT=$CROSS_BITMAP_SHIFT
make install
