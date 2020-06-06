#!/bin/bash
set -x

APPDIR=$PWD
cd $APPDIR
declare -a caparr=("1000" "2000" "4000" "8000")
declare -a apparr=("MADbench")

OUTPUTDIR=$APPBENCH/output


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


RUNAPP() {
	#Run application
	cd $APPDIR
	CAPACITY=$1

	if [ "$APP" = "MADbench" ]
	then
		cd $APPDIR/MADbench
		#$APPDIR/MADbench/run.sh $CAPACITY 
		echo $CAPACITY
	fi
	sudo dmesg -c &>> $OUTPUT
}


SET_RUN_APP() {	

	RUNAPP $1
}


for APP in "${apparr[@]}"
do
	for CAPACITY  in "${caparr[@]}"
	do
		#SETUPEXTRAM $CAPACITY
		SET_RUN_APP $CAPACITY
	done
done
