#!/bin/bash

PCAnonRatio=1.5
#APPPREFIX="numactl --membind=0"
APPPREFIX=""

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

NPROC=16
SEGMENTS=16
BLOCKSIZE=16m
TRANSFERSZ=1m
FILESPERPROC=-F

#$SHARED_LIBS/construct/reset
export LD_PRELOAD=$PREDICT_LIB_DIR/libcrosslayer.so
$APPPREFIX /usr/bin/time -v mpirun -n $NPROC src/ior -t $TRANSFERSZ -b $BLOCKSIZE -s $SEGMENTS $FILESPERPROC
export LD_PRELOAD=""
FlushDisk
