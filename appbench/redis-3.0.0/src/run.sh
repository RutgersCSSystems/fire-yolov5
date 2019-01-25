#!/bin/bash
APPBASE=$APPBENCH/redis-3.0.0/src
APP=$APPBASE/pagerank
PARAM=$1
OUTPUT=$2

cd $APPBASE
/bin/rm *.rdb
rm -rf *.aof
killall redis-server
sleep 5


FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

RUN(){
export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so
$APPPREFIX $APPBASE/redis-server $APPBENCH/redis-3.0.0/redis.conf &
export LD_PRELOAD=""
}

FlushDisk

alias rm=rm
RUN
sleep 5
$APPPREFIX $APPBASE/redis-benchmark -r 1000000 -n 4000000 -c 50 -t get,set -P 16 -q  -h 127.0.0.1 -p 6379 -d 4096 #&> $OUTPUT
killall redis-server





