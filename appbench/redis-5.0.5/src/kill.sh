#!/bin/bash
set -x
REDISROOT=$APPBENCH/redis-5.0.5
REDISCONF=$REDISROOT/config
APPBASE=$REDISROOT/src
#APPBASE=/usr/bin/
APP=$APPBASE/pagerank
PARAM=$1
OUTPUT=$2
READS=2000000
KEYS=4000000
CLIPREFIX="numactl --membind=0"
PHYSCPU="--physcpubind"

let MAXINST=4
let STARTPORT=6378
let SERVERCPU=20
let DATASIZE=1024

CLEAN() {
        for (( b=1; b<=$MAXINST; b++ ))
	do
		rm -rf *.rdb
		rm -rf *.aof
		sudo killall "redis-server$b"
		sudo killall "redis-server$b"
		kill -9 $(ps aux | grep 'redis-server1' | awk '{print $2}')
		kill -9 $(ps aux | grep 'redis-server2' | awk '{print $2}')
		kill -9 $(ps aux | grep 'redis-server3' | awk '{print $2}')
		kill -9 $(ps aux | grep 'redis-server4' | awk '{print $2}')
		echo "KILLING redis-server$b"
	done
	sudo killall redis-benchmark
	sudo killall redis-benchmark
}



FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

CLEAN
sleep 5
FlushDisk
CLEAN
set +x
