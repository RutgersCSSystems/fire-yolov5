#!/bin/bash


sudo apt update; sudo apt install mpich -y

./bootstrap
./configure
make -j`nproc`

sudo make install

##ior is the command

