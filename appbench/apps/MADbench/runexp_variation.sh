#!/bin/bash
#set -x

##prefetch window multiple factor 1, 2, 4
##grep the elapsed time, file faults, minor faults, system time, user time

APPDIR=$PWD
RESULTS_FOLDER=results-sensitivity-sudarsun
mkdir $RESULTS_FOLDER
cd $APPDIR
declare -a apparr=("MADbench")
declare -a predict=("0" "1")
#declare -a workarr=("4096" "8192" "16384")
declare -a workarr=("16384")
declare -a thrdarr=("16")
##application read size 4KB, 128KB, 512KB, 1MB, 4MB, 16MB
#declare -a readsize=("4096" "131072" "524288" "1048576" "4194304" "16777216")
declare -a readsize=("1048576")
#sizeofprefetch = prefetchwindow * readsize
declare -a prefetchwindow=("1" "2" "4")

#APPPREFIX="numactl --membind=0"
APPPREFIX=""
FLUSH=1 ##FLUSHES and clears cache AFTER EACH WRITE

export IOMODE=SYNC
export FILETYPE=UNIQUE
export IOMETHOD=POSIX

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
	RECORD=$5
	TPREFETCH=$6

	OUTPUT=$RESULTS_FOLDER/$APP"_PROC-"$NPROC"_PRED-"$PREDICT"_LOAD-"$WORKLOAD"_READSIZE-"$RECORD"_TIMESPFETCH-"$TPREFETCH".out"

	echo "*********** running $OUTPUT ***********"

	export TIMESPREFETCH=$TPREFETCH
	APPPREFIX="/usr/bin/time -v"

	numactl --hard &> $OUTPUT
	wait; sync

	if [[ "$PREDICT" == "1" ]]; then
		export LD_PRELOAD=/usr/lib/libcrosslayer.so
	else
		export LD_PRELOAD=/usr/lib/libnopred.so
	fi


	if [[ "$APP" == "MADbench" ]]; then
		echo "$APPPREFIX mpiexec -n $NPROC ./MADbench2_io $WORKLOAD 30 1 8 64 1 1 $RECORD $STRIDE $FLUSH"
		$APPPREFIX mpiexec -n $NPROC ./MADbench2_io $WORKLOAD 30 1 8 64 1 1 $FLUSH &>> $OUTPUT
		export LD_PRELOAD=""
		wait; sync
		echo "*******************DMESG OUTPUT******************" >> $OUTPUT
		dmesg | grep -v -F "systemd-journald" >> $OUTPUT
		wait; sync
	fi

}


make clean; make -j ##Make MADBench
REFRESH

for APP in "${apparr[@]}"
do
	for NPROC in "${thrdarr[@]}"
	do	
		for WORKLOAD in "${workarr[@]}"
		do
			for READSIZE in "${readsize[@]}"
			do
				for PREDICT in "${predict[@]}"
				do 
					for PREFETCHTIMES in "${prefetchwindow[@]}"
					do 

						RUNAPP $NPROC $WORKLOAD $APP $PREDICT $READSIZE $PREFETCHTIMES
						REFRESH
					done
				done
			done 
		done	
	done
done

git add $RESULTS_FOLDER
message="results_at "
message+=`date`
git commit -m "$message"
git push

##IMplement the per proc bg thread
