#!/bin/bash
#set -x

APPDIR=$PWD
cd $APPDIR
declare -a caparr=("5655")
declare -a thrdarr=("36")
declare -a workarr=("2000")
declare -a apparr=("BT")

#APPPREFIX="numactl --membind=0"
APPPREFIX=""

DMESGREADER="$HOME/ssd/NVM/appbench/apps/NPB3.4/NPB3.4-MPI/scripts/readdmesg.py"

#Make sure to compile and install perf
USEPERF=0
PERFTOOL="$HOME/ssd/NVM/linux-stable/tools/perf/perf"

SLEEPNOW() {
	sleep 2
}


SETPERF() {

	sudo sh -c "echo 0 > /proc/sys/kernel/perf_event_paranoid"
	sudo sh -c "echo 0 > /proc/sys/kernel/kptr_restrict"
	SLEEPNOW
}


#Mount ramdisk to reserve memory and reduce overall memory availability
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

	let DISKSZ=$NUMAFREE0-$SPLIT-712
	let ALLOCSZ=$NUMAFREE1-$SPLIT-712

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

	if [ "$APP" = "gromacs" ]
	then
		cd $APPDIR
		echo $CAPACITY
		mkdir results-sensitivity
		#		export LD_PRELOAD=/usr/lib/libmigration.so
		$APPPREFIX /usr/bin/time -v gmx mdrun -ntmpi $NPROC -ntomp 1 -nt $NPROC -s run_water.tpr -o -x -deffnm md_water 
		export LD_PRELOAD=""
		$DMESGREADER init
		#		while :
		#		do
		#			sleep 1
		#			if pgrep -x "gmx" >/dev/null
		#			then
		#				$DMESGREADER readfrom Cum_mem-$CAPACITY.csv
		#			else
		#				break
		#			fi
		#		done
		#		sleep 5
		./clean_out.sh
	fi

	if [ "$APP" = "BT" ]
	then
		cd $APPDIR
		echo $CAPACITY
		mkdir results-sensitivity
		#export LD_PRELOAD=/usr/lib/libmigration.so
		/usr/bin/time -v mpirun -NP $NPROC ./bin/bt.C.x.ep_io 
		rm -rf btio*
		export LD_PRELOAD=""
		$DMESGREADER init
		#while :
		#do
		#	sleep 1
		#	if pgrep -x "mpirun" >/dev/null
		#	then
		#		$DMESGREADER readfrom Cum_mem-$CAPACITY.csv
		#	else
		#		break
		#	fi
		#done
		#sleep 5
		rm -rf btio*
		SLEEPNOW
	fi

}


#Do all things during termination
TERMINATE() 
{
	CAPACITY=$1
	NPROC=$2
	WORKLOAD=$3

	OUTPUT=results-sensitivity/"PERF-MEMSIZE-$WORKLOAD-"$NPROC"threads-"$CAPACITY"M.out"

	if [[ $USEPERF == "1" ]]; then
		SLEEPNOW
		sudo $PERFTOOL report &>> $OUTPUT
		sudo $PERFTOOL report --sort=dso &>> $OUTPUT
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
				RUNAPP $CAPACITY $NPROC $WORKLOAD
				#sleep 5
				#./clear_cache.sh
			done
			$SHARED_LIBS/construct/reset
			RUNAPP $CAPACITY $NPROC $WORKLOAD $APP
			RUNAPP $CAPACITY $NPROC $WORKLOAD $APP
			RUNAPP $CAPACITY $NPROC $WORKLOAD $APP
			$SHARED_LIBS/construct/reset
			SLEEPNOW
			./clear_cache.sh
			TERMINATE $CAPACITY $NPROC $WORKLOAD
		done 
	done	
done
