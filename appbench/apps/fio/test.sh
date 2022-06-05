#!/bin/bash

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo dmesg --clear
    sleep 2
}

SIZE=2g
NUMJOBS=16


FlushDisk
#export LD_PRELOAD=/usr/lib/libjuststats.so
fio --name=nvme --directory=./fio-test --ioengine=psync --rw=read --bs=4k --numjobs=$NUMJOBS --size=$SIZE --iodepth=1 --fadvise_hint=0
#fio --name=nvme --directory=./fio-test --time_based --size=10G --direct=0 --verify=0 --bs=4K --iodepth=1024 --rw=read --group_reporting=1 --numjobs=4
#export LD_PRELOAD=""


#fio can do strided reads 
