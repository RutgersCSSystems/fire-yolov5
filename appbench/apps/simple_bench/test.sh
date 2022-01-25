#!/bin/bash

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo dmesg --clear
    sleep 1
}


KB=1024
MB=`echo "1024*$KB" | bc`
GB=`echo "1024*$MB" | bc`


#./write

FlushDisk

export APPCACHELIMIT=`echo "2*$GB" | bc`
export LD_PRELOAD=/usr/lib/libcache_lim_ospred.so

./read_onlyos

export LD_PRELOAD=""
