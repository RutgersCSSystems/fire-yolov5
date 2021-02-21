#!/bin/bash
OUTPUT="out.txt"
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

NPROC=32
SEGMENTS=1024
BLOCKSIZE=1m
TRANSFERSZ=1m
KEEP_FILES_AFTER_RUN=-k

#Make this to an empty value if no per-file process
#FILESPERPROC=-F
FILESPERPROC=


#$SHARED_LIBS/construct/reset
export LD_PRELOAD=$PREDICT_LIB_DIR/libcrosslayer.so
$APPPREFIX /usr/bin/time -v mpirun -n $NPROC src/ior -t $TRANSFERSZ -b $BLOCKSIZE -s $SEGMENTS $FILESPERPROC $KEEP_FILES_AFTER_RUN &>> $OUTPUT && grep -r "Elapsed" $OUTPUT
export LD_PRELOAD=""
FlushDisk


$APPPREFIX /usr/bin/time -v mpirun -n $NPROC src/ior -t $TRANSFERSZ -b $BLOCKSIZE -s $SEGMENTS $FILESPERPROC $KEEP_FILES_AFTER_RUN &>> $OUTPUT  && grep -r "Elapsed" $OUTPUT

FlushDisk
