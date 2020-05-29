#!/bin/bash
DIR=$1
DEFAULTSWAP="/dev/sda3"
sudo fallocate -l 2G $DIR/swapfile
sudo dd if=/dev/zero of=$DIR/swapfile bs=1024 count=1048576
sudo chmod 600 $DIR/swapfile
sudo mkswap $DIR/swapfile
sudo swapoff $DEFAULTSWAP
sudo swapon -s
