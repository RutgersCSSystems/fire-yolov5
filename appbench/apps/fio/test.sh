#!/bin/bash

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo dmesg --clear
}



FlushDisk
export LD_PRELOAD=/usr/lib/libjuststats.so
fio --name=nvme --directory=./fio-test --time_based --size=10G --runtime=28s --ramp_time=2s --ioengine=libaio --direct=0 --verify=0 --bs=4K --iodepth=1024 --rw=randread --group_reporting=1 --numjobs=4
export LD_PRELOAD=""
