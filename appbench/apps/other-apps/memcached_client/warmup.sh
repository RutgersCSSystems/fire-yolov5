#!/bin/sh
#(w - number of client threads, S - scaling factor, D - target server memory, T - statistics interval, s - server configuration file, j - an indicator that the server should be warmed up). 
set -x

BASEPATH=$APPBENCH/memcached
DATASET=$BASEPATH/dataset
killall memcached 
sudo killall memcached
sudo killall mysqld
killall sleep

sleep 5


#cd /root/codes/shared_libs/mmap_lib/
#make clean
#make
#sudo make install

#echo "allocating hetero..."
#sleep 10

cd $BASEPATH/memcached_client
numactl --preferred=1 $BASEPATH/memcached-1.4.15_serv/memcached -t 4 -m 4096 -n 200 -u root &
#./loader -a ../twitter_dataset/twitter_dataset_unscaled -o ../twitter_dataset/twitter_dataset_40x -s servers.txt -w 16 -S 40 -D 256 -j -T 1
sleep 5
./killer.sh &
numactl --preferred=0 ./loader -a ../twitter_dataset/twitter_dataset_25x -s servers.txt -g 0.8 -T 4 -c 100 -w 8
exit

