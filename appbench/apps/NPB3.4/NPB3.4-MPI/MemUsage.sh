#!/bin/bash
#set -x

sudo swapoff -a

APPDIR=$PWD
cd $APPDIR
declare -a caparr=("5500")
declare -a thrdarr=("36")
declare -a workarr=("100")
declare -a apparr=("BT")

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
	./clear_cache.sh

        SLEEPNOW

        NUMAFREE0=`numactl --hardware | grep "node 0 free:" | awk '{print $4}'`
        NUMAFREE1=`numactl --hardware | grep "node 1 free:" | awk '{print $4}'`

        let DISKSZ=$NUMAFREE0-$SPLIT
        let ALLOCSZ=$NUMAFREE1-$SPLIT

        echo "NODE 0 $DISKSZ NODE 1 $ALLOCSZ"

        ./mount_ext4ramdisk.sh $DISKSZ 0
        ./mount_ext4ramdisk.sh $ALLOCSZ 1

	SLEEPNOW
}

RUNAPP() 
{
	#Run application
	cd $APPDIR
	mkdir results-sensitivity

	CAPACITY=$1
	NPROC=$2
	WORKLOAD=$3
	APP=$4
	if [ "$APP" = "GTC" ]; then
		rm -rf DATA_RESTART*
		free -m > free-mem-$CAPACITY.dat
		$APPPREFIX mpiexec -n $NPROC ./gtc &

		while :
		do
			sleep 1
			if pgrep -x "mpiexec" >/dev/null
			then
				free -m >> free-mem-$CAPACITY.dat
			else
				sed -i '/Swap/d' free-mem-$CAPACITY.dat
				break
			fi
		done

	fi
	if [ "$APP" = "BT" ]
	then
		cd $APPDIR
		echo $CAPACITY
		mkdir results-sensitivity
		free -m > free-mem-$CAPACITY.dat
		/usr/bin/time -v mpirun -NP $NPROC ./bin/bt.C.x.ep_io &
		while :
		do
			sleep 1
			if pgrep -x "mpirun" >/dev/null
			then
				free -m >> free-mem-$CAPACITY.dat
			else
				sed -i '/Swap/d' free-mem-$CAPACITY.dat
				rm -rf btio*
				break
			fi
		done
	fi
}



for APP in "${apparr[@]}"
do
	for CAPACITY  in "${caparr[@]}"
	do 
		SETUPEXTRAM $CAPACITY

		for NPROC in "${thrdarr[@]}"
		do	
			for WORKLOAD in "${workarr[@]}"
			do
				RUNAPP $CAPACITY $NPROC $WORKLOAD $APP
				#SLEEPNOW
				rm -rf DATA*
			done 
		done	
	done
done
