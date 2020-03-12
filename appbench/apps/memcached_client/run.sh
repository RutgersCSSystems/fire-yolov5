#!/bin/bash
#set -x
#(w - number of client threads, S - scaling factor, D - target server memory, T - statistics interval, s - server configuration file, j - an indicator that the server should be warmed up).

set -x
PARAM=$1
OUTPUT=$2
DATA=twitter_dataset_unscaled
APPBASE=$APPBENCH/apps/memcached
APP=$APPBASE/memcached
#APP=/usr/bin/memcached
CLIENTBASE=$APPBENCH/apps/memcached_client
INPUT=$CLIENTBASE/$DATA
DATASET=$SHARED_DATA/twitter_dataset_200x
DATA=4096

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
sudo pkill -f memcached
killall sleep
}

RUNMEMCACHED() {
#LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so 
$APPPREFIX $APP -t 16 -m 8192 -n 200 &
}

RUN_WARMUP() {
cd $CLIENTBASE
sleep 5
#$CLIENTBASE/killer_load.sh &
$CLIENTBASE/loader -a $INPUT -o $DATASET -s $CLIENTBASE/servers.txt -w 32 -S 40 -D $DATA -j -T 1
}

RUN(){
cd $CLIENTBASE
$CLIENTBASE/killer.sh &
#export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so
#$APPPREFIX 
$CLIENTBASE/loader -a $DATASET -s $CLIENTBASE/servers.txt -g 0.8 -T 4 -c 100 -w 64
export LD_PRELOAD=""
}

FINISH
FLUSH_DISK
RUNMEMCACHED
RUN_WARMUP
sleep 5
RUN
FINISH
exit

