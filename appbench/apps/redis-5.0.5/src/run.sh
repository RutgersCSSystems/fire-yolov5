#!/bin/bash
set -x
PREDICT=1

REDISROOT=$APPBENCH/apps/redis-5.0.5
REDISCONF=$REDISROOT/config
APPBASE=$REDISROOT/src

OUTPUTDIR=$PWD/RESULTS
mkdir -p $OUTPUTDIR

PARAM=$1
OUTPUT=$2
READS=500000
KEYS=1000000
let MAXINST=4



#READS=10000
#KEYS=20000
CLIPREFIX="numactl --preferred=0"
PHYSCPU="--physcpubind"

let STARTPORT=6378
let SERVERCPU=20
let DATASIZE=4096
let physcpu=0
let physcpu2=1

SIGNAL="-9"


CLEAN() {
        for (( b=1; b<=$MAXINST; b++ ))
	do
		rm -rf *.rdb
		rm -rf *.aof
		sudo killall "redis-server$b"
		appname="redis-server$b"
		sudo kill $SIGNAL $appname
		sudo killall "redis-server$b"
		echo "KILLING redis-server$b"
		sudo kill $SIGNAL $appname
	done
	sudo killall redis-benchmark
	sudo killall redis-benchmark
}

PREPARE() {
        for (( inst=1; inst<=$MAXINST; inst++ ))
	do
		cd $APPBASE
		sudo rm redis-server$inst redis-benchmark$inst
		cp redis-server redis-server$inst
		cp redis-benchmark redis-benchmark$inst
		cd $APPBENCH
	done
}

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

BUILD_LIB()
{
	cd $SHARED_LIBS/pred
	./compile.sh
	cd $APPBASE
}

SETPRELOAD()
{
	if [[ "$PREDICT" == "1" ]]; then
	    export LD_PRELOAD=/usr/lib/libcrosslayer.so
	else
	    export LD_PRELOAD=/usr/lib/libnopred.so
	fi
}




RUN(){
  let port=$STARTPORT
  let physcpu=$SERVERCPU
  let physcpu2=$physcpu+1

  SETPRELOAD	  

  for (( r=1; r<=$MAXINST; r++))
  do
    $APPPREFIX $APPBASE/redis-server$r $REDISCONF/redis-$port".conf" &

    let port=$port+1
    let physcpu=$physcpu+2
    let physcpu2=$physcpu2+2   	
    sleep 1	
  done

  export LD_PRELOAD=""
}


RUNCLIENT(){
  let port=$STARTPORT

  let physcpu=2
  let physcpu2=3

  PARAMS=" -r $READS -n $KEYS -c 100 -t get,set -P 16 -q  -h 127.0.0.1 -d $DATASIZE"

  for (( c=1; c<$MAXINST; c++))
  do
    $CLIPREFIX $APPBASE/redis-benchmark$c $PARAMS -p $port &> $OUTPUTDIR/"predict"$PREDICT"_"redis$c".txt" &
    let port=$port+1
    let physcpu=$physcpu+1
    let physcpu2=$physcpu2+2   	
  done
  $CLIPREFIX  $APPBASE/redis-benchmark$c $PARAMS -p $port &> $OUTPUTDIR/"predict"$PREDICT"_"redis$c".txt" 
}


cd $REDISROOT/src
CLEAN
sleep 5
PREPARE
FlushDisk
cd $SHARED_DATA

RUN
sleep 10
RUNCLIENT
CLEAN
CLEAN

sleep 10
FlushDisk
PREDICT=0
RUN
sleep 10
RUNCLIENT
CLEAN
CLEAN


set +x
