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

export LD_PRELOAD=/usr/lib/libcache_lim_ospred.so

export APPCACHELIMIT=`echo "10*$GB" | bc`

