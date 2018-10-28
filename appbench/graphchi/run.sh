#!/bin/bash
set -x
#DATA=com-friendster.ungraph.txt
#DATA=sx-stackoverflow.txt
DATA=com-orkut.ungraph.txt
INPUT=$SHARED_DATA/$DATA
APPBASE=$APPBENCH/graphchi/graphchi-cpp/bin/example_apps
APP=$APPBASE/pagerank
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
echo "edgelist" | LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so $APPPREFIX /usr/bin/time -v $APP file $INPUT niters 32
#echo "edgelist" | /usr/bin/time -v $APPPREFIX $APP file $INPUT niters 32
export LD_PRELOAD=""
}

cd $APPBENCH/graphchi 
RUN
FlushDisk
set +x

