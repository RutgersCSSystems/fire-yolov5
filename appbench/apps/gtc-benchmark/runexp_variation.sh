#!/bin/bash
#set -x

APPDIR=$PWD
cd $APPDIR
declare -a caparr=("90000" "80000" "50000" "30000")
declare -a thrdarr=("32")
declare -a workarr=("100")
declare -a apparr=("GTC")

#APPPREFIX="numactl --membind=0"
APPPREFIX=""

SETUPEXTRAM() {

	let CAPACITY=$1

	let SPLIT=$CAPACITY/2
	echo "SPLIT" $SPLIT

        sudo rm -rf  /mnt/ext4ramdisk0/*
        sudo rm -rf  /mnt/ext4ramdisk1/*

	./umount_ext4ramdisk.sh 0
	./umount_ext4ramdisk.sh 1

        sleep 2

        NUMAFREE0=`numactl --hardware | grep "node 0 free:" | awk '{print $4}'`
        NUMAFREE1=`numactl --hardware | grep "node 1 free:" | awk '{print $4}'`

        let DISKSZ=$NUMAFREE0-$SPLIT
        let ALLOCSZ=$NUMAFREE1-$SPLIT

        echo "NODE 0 $DISKSZ NODE 1 $ALLOCSZ"

        ./mount_ext4ramdisk.sh $DISKSZ 0
        ./mount_ext4ramdisk.sh $ALLOCSZ 1

	sleep 5
}


RUNAPP() {
	#Run application
	cd $APPDIR
	CAPACITY=$1
	NPROC=$2
	WORKLOAD=$3

	if [ "$APP" = "MADbench" ]
	then
		cd $APPDIR
		mkdir results-sensitivity
		$APPPREFIX /usr/bin/time -v mpiexec -n $NPROC ./MADbench2_io $WORKLOAD 140 1 8 8 4 4 &> results-sensitivity/"MEMSIZE-$WORKLOAD-"$NPROC"threads-"$CAPACITY"M.out"
		echo $CAPACITY
	fi

	if [ "$APP" = "GTC" ]
	then
		cd $APPDIR
		mkdir results-sensitivity
		$APPPREFIX /usr/bin/time -v mpiexec -n $NPROC ./gtc &> results-sensitivity/"MEMSIZE-$WORKLOAD-"$NPROC"threads-"$CAPACITY"M.out"
		echo $CAPACITY
	fi
}


for APP in "${apparr[@]}"
do

	for CAPACITY  in "${caparr[@]}"
	do 
		./umount_ext4ramdisk.sh
		SETUPEXTRAM $CAPACITY

		for NPROC in "${thrdarr[@]}"
		do	
			for WORKLOAD in "${workarr[@]}"
			do
				RUNAPP $CAPACITY $NPROC $WORKLOAD
				sleep 5
				./clear_cache.sh
			done
		done	
	done
done
