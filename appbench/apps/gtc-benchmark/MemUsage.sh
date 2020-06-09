#!/bin/bash
#set -x

sudo swapoff -a

APPDIR=$PWD
cd $APPDIR
declare -a caparr=("22483")
declare -a thrdarr=("36")
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
	OUTPUT=results-sensitivity/"MEMSIZE-$WORKLOAD-"$NPROC"threads-"$CAPACITY"M.out"

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
}



for APP in "${apparr[@]}"
do
	for CAPACITY  in "${caparr[@]}"
	do 
		#SETUPEXTRAM $CAPACITY

		for NPROC in "${thrdarr[@]}"
		do	
			for WORKLOAD in "${workarr[@]}"
			do
				RUNAPP $CAPACITY $NPROC $WORKLOAD $APP
				#SLEEPNOW
				rm -rf DATA*
				./clear_cache.sh
				TERMINATE $CAPACITY $NPROC $WORKLOAD
			done 
		done	
	done
done
