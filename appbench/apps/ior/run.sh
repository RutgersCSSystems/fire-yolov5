#!/bin/bash
#$OUTPUTDIR is set in setvars.sh
OUTPUTVANILLA=$OUTPUTDIR/sudarsun/IOR/"vanilla.txt"
OUTPUTCROSS=$OUTPUTDIR/sudarsun/IOR/"crosslayer.txt"

mkdir -p $OUTPUTVANILLA
mkdir -p $OUTPUTCROSS

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
BLOCKSIZE=16m
TRANSFERSZ=1m

#KEEP_FILES_AFTER_RUN=-k
KEEP_FILES_AFTER_RUN=
#Sync after write operations
SYNCAFTERWRITE="-e"
#Make this to an empty value if no per-file process
FILESPERPROC="-F"
#FILESPERPROC=
#(reorderTasks) to do this, and it forces each MPI process to read the data written by its
#neighboring node. Running IOR with this option gives much more credible read performance:
REORDER="-C"

FlushDisk

OPTIONS="-t $TRANSFERSZ -b $BLOCKSIZE -s $SEGMENTS $FILESPERPROC $KEEP_FILES_AFTER_RUN $SYNCAFTERWRITE $REORDER"

OUTPUT=$OUTPUTCROSS
rm $OUTPUT
export LD_PRELOAD=$PREDICT_LIB_DIR/libcrosslayer.so
$APPPREFIX /usr/bin/time -v mpirun -n $NPROC src/ior $OPTIONS &> $OUTPUT && grep -r "Elapsed" $OUTPUT
export LD_PRELOAD=""
FlushDisk


OUTPUT=$OUTPUTVANILLA
rm $OUTPUT
$APPPREFIX /usr/bin/time -v mpirun -n $NPROC src/ior $OPTIONS &> $OUTPUT  && grep -r "Elapsed" $OUTPUT
FlushDisk
