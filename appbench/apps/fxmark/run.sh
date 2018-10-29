#!/bin/bash
set -x
APPBASE=$APPBENCH/apps/fxmark
APP=$APPBASE/bin/fxmark
DATA=$APPBASE/DATA
SIZE=" --size=10G"
PARAM=" --type DWOL --ncore 32 --nbg 1 --duration 30 --directio 0 --root=$DATA"
OUTPUT=$2
mkdir $DATA

FlushDisk()
{
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
	sudo sh -c "sync"
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

RANDOM_READ(){
echo "Running Random Read"
#$APPPREFIX $APP $PARAM
LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so $APPPREFIX $APP $PARAM
}


cd $APPBASE
#FlushDisk
##RANDOM_WRITE
FlushDisk
RANDOM_READ
FlushDisk
rm $DATA/*
set +x

