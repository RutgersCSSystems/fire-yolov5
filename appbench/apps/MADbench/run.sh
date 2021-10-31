#!/bin/bash

PCAnonRatio=1.5
#DBGRATIO=1
#DRATIO=100
#BASE_MEM=2758459392
#APPPREFIX="numactl --membind=0"
APPPREFIX=""

CAPACITY=$1

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

SETUPEXTRAM() {

        sudo rm -rf  /mnt/ext4ramdisk0/*
        sudo rm -rf  /mnt/ext4ramdisk1/*
	./umount_ext4ramdisk.sh 0
	./umount_ext4ramdisk.sh 1
        sleep 5
        NUMAFREE0=`numactl --hardware | grep "node 0 free:" | awk '{print $4}'`
        NUMAFREE1=`numactl --hardware | grep "node 1 free:" | awk '{print $4}'`
        let DISKSZ=$NUMAFREE0-$CAPACITY
        let ALLOCSZ=$NUMAFREE1-300
        echo $DISKSZ"*************"
        #./umount_ext4ramdisk.sh 0
        #./umount_ext4ramdisk.sh 1
        ./mount_ext4ramdisk.sh $DISKSZ 0
        ./mount_ext4ramdisk.sh $ALLOCSZ 1
}

#SETUPEXTRAM
echo "going to sleep"
#IOMETHOD = POSIX  IOMODE = SYNC  FILETYPE = UNIQUE  REMAP = CUSTOM

export FILETYPE=SHARED
WORKLOAD=2000
NPROC=16
GANG=80
RMOD=16
WMOD=16

#export IOMODE=SYNC
#export IOMETHOD=POSIX
#$SHARED_LIBS/construct/reset

#export LD_PRELOAD=/usr/lib/libcrosslayer.so
$APPPREFIX /usr/bin/time -v mpiexec -n $NPROC ./MADbench2_io $WORKLOAD $GANG 1 8 8 $RMOD $WMOD  #&> "MEMSIZE-$WORKLOAD-"$NPROC"threads-"$CAPACITY"M.out"
export LD_PRELOAD=""
FlushDisk
