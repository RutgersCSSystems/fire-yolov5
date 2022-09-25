#!/bin/bash

##This compile script will compile the preload libraries and install them

#OS doesnt prefetch more than 256 pages in vanilla kernel

# PREFETCH_SIZE should be greater than 64 pages else
#there will be duplicate copy_to_user in readahead_info and
# performance will go down.

#sudo apt update; sudo apt install mpich -y

PREFETCH_SIZE=4096
NR_WORKERS=2
CROSS_BITMAP_SHIFT=37
NR_PREDICT_SAMPLE_FREQ=8
make install
