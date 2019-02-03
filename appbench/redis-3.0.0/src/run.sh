#!/bin/bash
#set -x
REDISROOT=$APPBENCH/redis-3.0.0
APPBASE=$REDISROOT/src
APP=$APPBASE/pagerank
PARAM=$1
OUTPUT=$2
READS=2000000
KEYS=4000000
CLIPREFIX="numactl --membind=0"
PHYSCPU="--physcpubind"

cd $APPBASE
let MAXINST=8
let STARTPORT=6378
let SERVERCPU=20

CLEAN() {

        for (( n=1; n<=$MAXINST; n++ ))
	do
		rm -rf *.rdb
		rm -rf *.aof
		killall redis-server$n
	done
	sleep 5
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
  for (( n=1; n<=$MAXINST; n++))
  do
    LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so $APPPREFIX $PHYSCPU=$physcpu $APPBASE/redis-server$n $REDISROOT/redis-$port".conf" &
    let port=$port+1
    let physcpu=$physcpu+1
  done
  export LD_PRELOAD=""
}

RUNCLIENT(){
  let port=$STARTPORT
  let physcpu=$SERVERCPU
  PARAMS=" -r $READS -n $KEYS -c 100 -t get,set -P 16 -q  -h 127.0.0.1 -d 1024"

  for (( n=1; n<$MAXINST; n++))
  do
    $CLIPREFIX $PHYSCPU=$physcpu $APPBASE/redis-benchmark $PARAMS -p $port &> $OUTPUTDIR/redis$n".txt" &
    let port=$port+1
    let physcpu=$physcpu+1
  done
  $CLIPREFIX $PHYSCPU=$physcpu $APPBASE/redis-benchmark $PARAMS -p $port &> $OUTPUTDIR/redis$n".txt"  
}

CLEAN
FlushDisk
RUN
sleep 10
RUNCLIENT
sleep 10
CLEAN
