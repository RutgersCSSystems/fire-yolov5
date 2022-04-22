#!/bin/bash

##This compile script will compile the preload libraries and install them

#OS doesnt prefetch more than 256 pages in vanilla kernel
PREFETCH_SIZE=512 ##in nr of pages
NR_WORKERS=4

make NR_RA_PAGES=$PREFETCH_SIZE NR_WORKERS=$NR_WORKERS -j
make install
