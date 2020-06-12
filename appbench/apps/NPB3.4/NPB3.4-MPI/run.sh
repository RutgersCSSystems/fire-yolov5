#!/bin/bash

PCAnonRatio=1.5
#DBGRATIO=1
#DRATIO=100
#BASE_MEM=2758459392
NPROC=36

APPPREFIX="numactl --membind=0"

#ProgMem=`echo "74828 * $NPROC * 1024" | bc` #in bytes For size C
#TotalMem=`echo "$ProgMem * $PCAnonRatio" | bc`
#TotalMem=`echo $TotalMem | perl -nl -MPOSIX -e 'print ceil($_)'`

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
        let ALLOCSZ=$NUMAFREE1-1024
        echo $DISKSZ"*************"
        #./umount_ext4ramdisk.sh 0
        #./umount_ext4ramdisk.sh 1
        ./mount_ext4ramdisk.sh $DISKSZ 0
        ./mount_ext4ramdisk.sh $ALLOCSZ 1
}

FlushDisk
#SETUPEXTRAM
echo "going to sleep"
sleep 10

APPPOSTFIX=" | grep 'MaxRSS' | awk 'BEGIN {FS = ' '} ; {sum+=\$2} END {print sum}'"

$SHARED_LIBS/construct/reset
export LD_PRELOAD=/usr/lib/libmigration.so 
$APPPREFIX /usr/bin/time -v mpirun -NP $NPROC ./bin/bt.C.x.ep_io
export LD_PRELOAD=""

#$APPPREFIX /usr/bin/time -v mpirun -NP $NPROC ./bin/bt.C.x.ep_io 
#/usr/bin/time -v mpirun -NP $NPROC ./bin/bt.C.x.ep_io
rm -rf btio*
FlushDisk
./umount_ext4ramdisk.sh 0
./umount_ext4ramdisk.sh 1

#sudo cgcreate -g memory:npb
#echo $TotalMem | sudo tee /sys/fs/cgroup/memory/npb/memory.limit_in_bytes

#sudo echo $DRATIO > /proc/sys/vm/dirty_ratio
#sudo echo $DBGRATIO > /proc/sys/vm/dirty_background_ratio

#export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so 
#$APPPREFIX  

#/usr/bin/time -v cgexec -g memory:npb mpirun -NP $NPROC ./bin/bt.C.x.ep_io

export LD_PRELOAD=""

