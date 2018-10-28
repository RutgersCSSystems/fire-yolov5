#!/bin/sh
set -x
#DATA=$SHARED_DATA/crime.data
#DATA=$SHARED_DATA/com-friendster.ungraph.txt
DATA=$SHARED_DATA/com-orkut.ungraph.txt
BASE=$APPBENCH/Metis
APPBASE=$BASE/obj
APP=$APPBASE/wc
PARAM=$1
OUTPUT=$2

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}


LoadtoRamDisk()
{
  #remout ramdisk
  sudo umount /tmp/ramdisk/
  ~/codes/nvmalloc/nvkernel_test_code/ramdisk_create.sh 2048
  cp $SHARED_DATA/$DATA /tmp/ramdisk
  SHARED_DATA=/tmp/ramdisk
}

RUN(){
LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so $APPPREFIX $APP $DATA 
export LD_PRELOAD=""
}


cd $APPBASE
FlushDisk
RUN
set +x
exit
