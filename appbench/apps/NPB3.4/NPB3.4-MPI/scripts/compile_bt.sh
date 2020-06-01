#!/bin/bash

LOAD=C

mkdir ./bin
cd ./shared_libs
make
make install
cd ..

make bt CLASS=$LOAD SUBTYPE=epio
