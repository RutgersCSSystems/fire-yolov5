#!/bin/bash
set -x

#Compile and install shared library
cd $CODESRC/shared_libs/construct
make clean && make
sudo make install

