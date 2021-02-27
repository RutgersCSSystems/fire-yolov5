#!/bin/bash
#set -x

APPDIR=$PWD
mkdir results-sensitivity
cd $APPDIR

declare -a predict=("0" "1")
declare -a workarr=("4096" "8192" "16384")
declare -a thrdarr=("1" "4" "9" "16")
declare -a apparr=("MADbench")

#APPPREFIX="numactl --membind=0"
APPPREFIX=""

export IOMODE=SYNC
export FILETYPE=UNIQUE
export IOMETHOD=POSIX

RECORD=1048576 # bytes read at once
STRIDE=7 # set stride to $STRIDE * RECORD_SIZE

REFRESH() {
	export LD_PRELOAD=""
	rm -rf files/
	$NVMBASE/scripts/clear_cache.sh
	sudo sh -c "dmesg --clear" ##clear dmesg
	sleep 2
}

#Here is where we run the application
RUNAPP() 
{
	echo "**********RUNAPP**********"
	#Run application
	cd $APPDIR

	NPROC=$1
	WORKLOAD=$2
	APP=$3
	PREDICT=$4


	#OUTPUT=results-sensitivity/"MEMSIZE-$WORKLOAD-"$NPROC"threads-"$CAPACITY"M.out"
	OUTPUT=results-sensitivity/$APP"_PROC-"$NPROC"PRED-"$PREDICT"LOAD-"$WORKLOAD".out"

	echo "*********** running $OUTPUT ***********"

	APPPREFIX="/usr/bin/time -v"

	if [[ "$PREDICT" == "1" ]]; then
		export LD_PRELOAD=/usr/lib/libcrosslayer.so
	else
		export LD_PRELOAD=/usr/lib/libnopred.so
	fi


	if [[ "$APP" == "MADbench" ]]; then
		echo "$APPPREFIX mpiexec -n $NPROC ./MADbench2_io $WORKLOAD 8 1 8 64 1 1 $RECORD $STRIDE $PREDICT"
		$APPPREFIX mpiexec -n $NPROC ./MADbench2_io $WORKLOAD 8 1 8 64 1 1 $RECORD $STRIDE $PREDICT &> $OUTPUT
		sync
		echo "*******************DMESG OUTPUT******************" >> $OUTPUT
		sync
		dmesg | grep -v -F "systemd-journald" >> $OUTPUT
		sync
	fi

	export LD_PRELOAD=""
}


make clean; make -j ##Make MADBench
REFRESH

for APP in "${apparr[@]}"
do
	for NPROC in "${thrdarr[@]}"
	do	
		for WORKLOAD in "${workarr[@]}"
		do
			for PREDICT in "${predict[@]}"
			do 
				RUNAPP $NPROC $WORKLOAD $APP $PREDICT
				REFRESH
			done 
		done	
	done
done
