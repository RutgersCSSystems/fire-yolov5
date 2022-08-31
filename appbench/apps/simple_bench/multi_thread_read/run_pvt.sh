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

./bin/write_pvt

echo "Read Pvt Seq Vanilla RA"
FlushDisk
ENABLE_LOCK_STATS
export LD_PRELOAD="/usr/lib/lib_Vanilla.so"
./bin/read_pvt_seq_vanilla
export LD_PRELOAD=""
DISABLE_LOCK_STATS
dmesg
sudo cat /proc/lock_stat


echo "Read Pvt Seq Vanilla RA OPT"
FlushDisk
ENABLE_LOCK_STATS
export LD_PRELOAD="/usr/lib/lib_Vanilla.so"
./bin/read_pvt_seq_vanilla_opt
export LD_PRELOAD=""
DISABLE_LOCK_STATS
dmesg
sudo cat /proc/lock_stat


echo "OS Only"
FlushDisk
ENABLE_LOCK_STATS
export LD_PRELOAD="/usr/lib/lib_OSonly.so"
./bin/read_pvt_seq_vanilla_opt
export LD_PRELOAD=""
DISABLE_LOCK_STATS
dmesg
sudo cat /proc/lock_stat


echo "Cross Info"
FlushDisk
ENABLE_LOCK_STATS
export LD_PRELOAD="/usr/lib/lib_Cross_Info.so"
./bin/read_pvt_seq
export LD_PRELOAD=""
DISABLE_LOCK_STATS
dmesg
sudo cat /proc/lock_stat


echo "Cross Info IOOPT"
FlushDisk
ENABLE_LOCK_STATS
export LD_PRELOAD="/usr/lib/lib_CII.so"
./bin/read_pvt_seq
export LD_PRELOAD=""
DISABLE_LOCK_STATS
dmesg
sudo cat /proc/lock_stat
