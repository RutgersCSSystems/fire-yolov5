#!/bin/bash
export NVMALLOC_HOME=$PWD/nvmalloc
sudo apt-get install libnetcdf-dev libnetcdff-dev -y
make clean
make

