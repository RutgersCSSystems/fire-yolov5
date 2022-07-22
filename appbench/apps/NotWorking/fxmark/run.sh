#!/bin/bash
set -x
APPBASE=$APPBENCH/apps/fxmark
APP=$APPBASE/bin/fxmark
#DATA=$APPBASE/DATA
DATA=$SHARED_DATA
SIZE=" --size=10G"
TYPE=" --type DRBL"
PARAM="$TYPE --ncore 8 --nbg 1 --duration 30 --directio 0 --root=$DATA"

OUTPUT=$2

if [ -z "$DATA" ]
then
      DATA=$PWD/data
fi

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
rm -rf $DATA/*
#$APPPREFIX $APP $PARAM
LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so $APPPREFIX $APP $PARAM
}


cd $APPBASE
FlushDisk
TYPE=" --type DWAL"
PARAM="$TYPE --ncore 8 --nbg 1 --duration 30 --directio 0 --root=$DATA"
RANDOM_READ
FlushDisk
rm $DATA/*

TYPE=" --type DRBL"
PARAM="$TYPE --ncore 8 --nbg 1 --duration 30 --directio 0 --root=$DATA"
RANDOM_READ
FlushDisk
rm $DATA/*

TYPE=" --type DWOL"
PARAM="$TYPE --ncore 8 --nbg 1 --duration 30 --directio 0 --root=$DATA"
RANDOM_READ
FlushDisk
rm $DATA/*



set +x

