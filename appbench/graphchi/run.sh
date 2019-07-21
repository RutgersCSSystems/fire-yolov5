#!/bin/bash
set -x
#DATA=com-friendster.ungraph.txt
#DATA=sx-stackoverflow.txt
#DATA=com-orkut.ungraph.txt
DATA=$SHARED_DATA
INPUT=/users/skannan/ssd/flashxdata/com-friendster.ungraph.txt
#INPUT=/mnt/ext4ramdisk/com-friendster.ungraph.txt
APPBASE=$APPBENCH/graphchi/graphchi-cpp/bin/example_apps
APP=$APPBASE/connectedcomponents
#APP=$APPBASE/randomwalks
#APP=$APPBASE/connectedcomponents
PARAM=$1
OUTPUT=$2

FlushDisk()
{
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
	sudo sh -c "sync"
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

RUN(){
rm -rf $SHARED_DATA/$DATA.*
#export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so
#/usr/bin/time -v
#echo "edgelist" | LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so $APPPREFIX /usr/bin/time -v $APP file $INPUT niters 4
echo "edgelist" | /usr/bin/time -v $APPPREFIX $APP file $INPUT niters 4
export LD_PRELOAD=""
rm -rf $SHARED_DATA/$DATA.*
}

cd $APPBENCH/graphchi/graphchi-cpp
RUN
FlushDisk
rm -rf $SHARED_DATA/$DATA.*
set +x

