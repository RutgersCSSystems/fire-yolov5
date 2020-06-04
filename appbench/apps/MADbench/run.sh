#!/bin/bash

PCAnonRatio=1.5
#DBGRATIO=1
#DRATIO=100
#BASE_MEM=2758459392
NPROC=36

APPPREFIX="numactl --membind=0"

ProgMem=`echo "74828 * $NPROC * 1024" | bc` #in bytes For size C
TotalMem=`echo "$ProgMem * $PCAnonRatio" | bc`
TotalMem=`echo $TotalMem | perl -nl -MPOSIX -e 'print ceil($_)'`

CAPACITY=$1

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

SETUPEXTRAM() {

        sudo rm -rf  /mnt/ext4ramdisk/*
        sleep 5
	./umount_ext4ramdisk.sh	
	./clear_cache.sh

        NUMAFREE=`numactl --hardware | grep "node 0 free:" | awk '{print $4}'`
	echo "NUMAFREE: "$NUMAFREE
        let DISKSZ=$NUMAFREE-$CAPACITY
        echo $DISKSZ"*************"
        ./umount_ext4ramdisk.sh
        ./mount_ext4ramdisk.sh $DISKSZ
}

FlushDisk
SETUPEXTRAM
echo "going to sleep"
sleep 10

$APPPREFIX /usr/bin/time -v mpiexec -n $NPROC ./MADbench2.x 2400 140 1 8 8 4 4

#/usr/bin/time -v mpirun -NP $NPROC ./bin/bt.C.x.ep_io
rm -rf btio*
FlushDisk

export LD_PRELOAD=""

