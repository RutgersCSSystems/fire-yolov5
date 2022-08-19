#!/bin/bash
set -x

sudo apt install cmake g++ libaio-dev libgoogle-perftools-dev clang-format libboost-all-dev
sudo apt install libmkl-full-dev
mkdir build 
cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make -j 
cd ..

mkdir -p build/data 
cd build/data
wget ftp://ftp.irisa.fr/local/texmex/corpus/sift.tar.gz
tar -xf sift.tar.gz
cd ..
./tests/utils/fvecs_to_bin data/sift/sift_learn.fvecs data/sift/sift_learn.fbin
./tests/utils/fvecs_to_bin data/sift/sift_query.fvecs data/sift/sift_query.fbin
