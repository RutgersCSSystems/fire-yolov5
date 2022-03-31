#!/bin/bash

##This compile script will compile the preload libraries and install them

PREFETCH_SIZE=120 ##in nr of pages
NR_WORKERS=4

make NR_RA_PAGES=$PREFETCH_SIZE NR_WORKERS=$NR_WORKERS -j
make install
