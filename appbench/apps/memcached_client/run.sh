#!/bin/bash
#set -x
#(w - number of client threads, S - scaling factor, D - target server memory, T - statistics interval, s - server configuration file, j - an indicator that the server should be warmed up).

set -x
PARAM=$1
OUTPUT=$2
DATA=twitter_dataset_unscaled
APPBASE=$APPBENCH/apps/memcached
APP=$APPBASE/memcached
CLIENTBASE=$APPBENCH/apps/memcached_client
INPUT=$CLIENTBASE/$DATA
DATASET=$SHARED_DATA/twitter_dataset_40x

FLUSH_DISK()
{
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
	sudo sh -c "sync"
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

FINISH()
{
killall memcached
sudo killall memcached
killall sleep
}

RUNMEMCACHED() {
$APP -t 4 -m 4096 -n 200 -u kannan11 &
}

RUN_WARMUP() {
sleep 5
cd $CLIENTBASE
RUNMEMCACHED
#$CLIENTBASE/killer_load.sh &
$CLIENTBASE/loader -a $INPUT -o $DATASET -s $CLIENTBASE/servers.txt -w 32 -S 40 -D 256 -j -T 1
}

RUN(){
cd $CLIENTBASE
$CLIENTBASE/killer.sh &
export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so
$CLIENTBASE/loader -a $DATASET -s $CLIENTBASE/servers.txt -g 0.8 -T 1 -c 100 -w 32
export LD_PRELOAD=""
}


FLUSH_DISK
RUN_WARMUP
#RUNMEMCACHED
sleep 5
RUN
FINISH
exit

