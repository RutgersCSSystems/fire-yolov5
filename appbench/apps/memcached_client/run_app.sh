#!/bin/sh

#./loader -a ../twitter_dataset/twitter_dataset_unscaled -o ../twitter_dataset/twitter_dataset_10x -s servers.txt -w 4 -S 20 -D 4096 -j -T 1

./loader -a  ../twitter_dataset/twitter_dataset_10x -s servers.txt -w 8  -D 512 -j -T 4
 #taskset --cpu-list 5,6,7 ./loader -a ../twitter_dataset/twitter_dataset_10x -s servers.txt -w 8  -D 256 -j -T 4 #-g 0.5 -T 4 -c 100 -w 16 #&> $MAXHOTPAGE"_fastmem_exec_full.    out"
