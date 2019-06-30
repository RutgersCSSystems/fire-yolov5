#!/bin/bash
#set -x
REDISROOT=$APPBENCH/redis-3.0.0
REDISCONF=$REDISROOT/config
APPBASE=$REDISROOT/src
APP=$APPBASE/pagerank
PARAM=$1
OUTPUT=$2
READS=1000000
KEYS=2000000
CLIPREFIX="numactl --membind=0"
PHYSCPU="--physcpubind"

cd $APPBASE
let MAXINST=2
let STARTPORT=6378
let SERVERCPU=20

CLEAN() {
        for (( b=1; b<=$MAXINST; b++ ))
	do
		rm -rf *.rdb
		rm -rf *.aof
		sudo killall "redis-server$b"
		sudo killall "redis-server$b"
		echo "KILLING redis-server$b"
	done
}

PREPARE() {
        for (( inst=1; inst<=$MAXINST; inst++ ))
	do
		cp redis-server redis-server$inst
	done
}

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

RUN(){
  let port=$STARTPORT
  let physcpu=$SERVERCPU
  for (( r=1; r<=$MAXINST; r++))
  do
    LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so $APPPREFIX $PHYSCPU=$physcpu $APPBASE/redis-server$r $REDISCONF/redis-$port".conf" &
    let port=$port+1
    let physcpu=$physcpu+1
  done
  export LD_PRELOAD=""
}

RUNCLIENT(){
  let port=$STARTPORT
  let physcpu=$SERVERCPU
  PARAMS=" -r $READS -n $KEYS -c 100 -t get,set -P 16 -q  -h 127.0.0.1 -d 1024"

  for (( c=1; c<$MAXINST; c++))
  do
    $CLIPREFIX $PHYSCPU=$physcpu $APPBASE/redis-benchmark $PARAMS -p $port &> $OUTPUTDIR/redis$c".txt" &
    let port=$port+1
    let physcpu=$physcpu+1
  done
  $CLIPREFIX $PHYSCPU=$physcpu $APPBASE/redis-benchmark $PARAMS -p $port &> $OUTPUTDIR/redis$c".txt"  
  sleep 5
  ps aux | grep redis-server | awk '{print $2; system("sudo kill -9 " $2); kill $(pgrep -f redis-server)}'
}

CLEAN
sleep 5
PREPARE
FlushDisk
RUN
sleep 10
RUNCLIENT
CLEAN
CLEAN
