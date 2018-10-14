#!/bin/bash
set -x
APPBASE=$APPBENCH/apps/spark
APP=docker
PARAM=$1
OUTPUT=$2

SETUP() {
sudo docker ps -a | grep minutes | awk '{PROC=$1; system(sudo docker stop  PROC); system(sudo docker rm  PROC)}'
sudo docker create --name data cloudsuite/twitter-dataset-graph
}

FlushDisk()
{
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
	sudo sh -c "sync"
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

RUN(){
#LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so
sudo LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so $APPPREFIX $APP run --rm --volumes-from data cloudsuite/graph-analytics --driver-memory 16g --executor-memory 32g
export LD_PRELOAD=""
}

SETUP
cd $APPBASE
RUN
set +x
