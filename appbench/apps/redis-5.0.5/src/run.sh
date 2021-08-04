#!/bin/bash
set -x
REDISROOT=$APPBENCH/apps/redis-5.0.5
REDISCONF=$REDISROOT/config
APPBASE=$REDISROOT/src
PARAM=$1
OUTPUT=$2
READS=1000000
KEYS=4000000
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
#SIGNAL="-9"


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

RUN(){
  let port=$STARTPORT
  let physcpu=$SERVERCPU
  let physcpu2=$physcpu+1

  for (( r=1; r<=$MAXINST; r++))
  do
    #LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so 
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
    # $PHYSCPU=$physcpu
    $CLIPREFIX $APPBASE/redis-benchmark$c $PARAMS -p $port &> $OUTPUTDIR/redis$c".txt" &
    #$CLIPREFIX $APPBASE/../memtier_benchmark/memtier_benchmark -s localhost -p $port -d 2 --pipeline=10 --threads=50 -c 50 --key-pattern=S:S --ratio=1:1 -n $KEYS --out-file $OUTPUTDIR/redis$c".txt"  --data-size=4096 &

    let port=$port+1
    let physcpu=$physcpu+1
    let physcpu2=$physcpu2+2   	
  done
  #$PHYSCPU=$physcpu
  #$PHYSCPU=$physcpu 
  $CLIPREFIX  $APPBASE/redis-benchmark$c $PARAMS -p $port &> $OUTPUTDIR/redis$c".txt"

  let port=$STARTPORT
  for (( c=1; c<=$MAXINST; c++))
  do
   # $CLIPREFIX $APPBASE/redis-benchmark$c $PARAMS -p $port shutdown &> $OUTPUTDIR/redis$c".txt" 
    let port=$port+1
  done
  #sleep 5
  #ps aux | grep redis-server | awk '{print $2; system("sudo kill -9 " $2); kill $(pgrep -f redis-server)}'
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
#$SHARED_LIBS/construct/reset
set +x
