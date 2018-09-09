#!/bin/bash
set -x
DATA=com-orkut.ungraph.txt
#DATA=soc-LiveJournal1.txt
INPUT=$SHARED_DATA/$DATA
APPBASE=$APPBENCH/graphchi/graphchi-cpp/bin/example_apps
APP=$APPBASE/pagerank
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
export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so
echo "edgelist" | /usr/bin/time -v $APPPREFIX $APP file $INPUT niters 8
export LD_PRELOAD=""
}

cd $APPBENCH/graphchi 
FlushDisk
RUN
set +x

