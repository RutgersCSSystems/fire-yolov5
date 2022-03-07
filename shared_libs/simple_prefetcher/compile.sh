#!/bin/bash

##This compile script will compile the preload libraries and install them

PREFETCH_SIZE=40 ##in nr of pages

make NR_RA_PG=$PREFETCH_SIZE -j
make install
