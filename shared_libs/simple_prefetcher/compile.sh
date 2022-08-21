#!/bin/bash

##This compile script will compile the preload libraries and install them

#OS doesnt prefetch more than 256 pages in vanilla kernel

# PREFETCH_SIZE should be greater than 64 pages else
#there will be duplicate copy_to_user in readahead_info and
# performance will go down.
PREFETCH_SIZE=4096 ##in nr of pages
NR_WORKERS=2

make NR_RA_PAGES=$PREFETCH_SIZE NR_WORKERS=$NR_WORKERS -j
make install
