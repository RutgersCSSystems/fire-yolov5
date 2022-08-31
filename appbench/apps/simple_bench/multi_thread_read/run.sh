#!/bin/bash

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sleep 5
    sudo dmesg --clear
}

ENABLE_LOCK_STATS()
{
	sudo sh -c "echo 0 > /proc/lock_stat"
	sudo sh -c "echo 1 > /proc/sys/kernel/lock_stat"
}

DISABLE_LOCK_STATS()
{
	sudo sh -c "echo 0 > /proc/sys/kernel/lock_stat"
}


FlushDisk

ENABLE_LOCK_STATS
#export LD_PRELOAD="/usr/lib/lib_CII.so"
#export LD_PRELOAD="/usr/lib/lib_VRA.so"
#export LD_PRELOAD="/usr/lib/lib_CII_sync.so"
#export LD_PRELOAD="/usr/lib/lib_Cross_Info.so"
#export LD_PRELOAD="/usr/lib/lib_Cross_Info_sync.so"
#export LD_PRELOAD="/usr/lib/lib_Cross_Info.so"
export LD_PRELOAD="/usr/lib/lib_CII.so"
./bin/read_shared_seq
export LD_PRELOAD=""
DISABLE_LOCK_STATS

dmesg
sudo cat /proc/lock_stat
