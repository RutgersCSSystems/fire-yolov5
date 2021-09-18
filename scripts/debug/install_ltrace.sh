#!/bin/bash

sudo apt update; sudo apt install libunwind-dev

git clone https://gitlab.com/cespedes/ltrace.git
cd ltrace
./configure --disable-werror --with-libunwind --enable-dependency-tracking
make -j
cd -
