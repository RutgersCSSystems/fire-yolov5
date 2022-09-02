#!/bin/bash
sudo apt update
sudo apt-get install libtool -y
sudo apt-get install bison -y
libtoolize
aclocal
autoheader
automake --add-missing
autoconf

./configure

make clean
make -j$(nproc)
