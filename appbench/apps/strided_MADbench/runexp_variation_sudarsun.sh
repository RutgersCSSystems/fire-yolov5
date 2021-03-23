#!/bin/bash
#set -x

if [ -z "$NVMBASE" ]; then
	echo "NVMBASE environment variable not defined. Have you ran setvars?"
	exit 1
fi

##prefetch window multiple factor 1, 2, 4
##grep the elapsed time, file faults, minor faults, system time, user time

APP="strided_MADbench"
RIGHTNOW=`date +"%H-%M_%m-%d-%y"`
APPDIR=$APPS/strided_MADbench
RESULTS_FOLDER=$OUTPUTDIR/$APP/bg-thpool-sensitivity-$RIGHTNOW
mkdir -p $RESULTS_FOLDER
cd $APPDIR

declare -a predict=("0" "1")
declare -a workarr=("4096" "8192" "16384")
declare -a thrdarr=("1" "4" "16")
##application read size 4KB, 128KB, 512KB, 1MB, 4MB, 16MB
declare -a readsize=("4096" "131072" "524288" "1048576" "4194304" "16777216")
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
	$NVMBASE/scripts/compile-install/clear_cache.sh
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
	PREDICT=$3
	RECORD=$4
	TPREFETCH=$5

	OUTPUT=$RESULTS_FOLDER/$APP"_PROC-"$NPROC"_PRED-"$PREDICT"_LOAD-"$WORKLOAD"_READSIZE-"$RECORD"_TIMESPFETCH-"$TPREFETCH".out"

	echo "*********** running $OUTPUT ***********"

	export TIMESPREFETCH=$TPREFETCH
	APPPREFIX="/usr/bin/time -v"

	if [[ "$PREDICT" == "1" ]]; then
		export LD_PRELOAD=/usr/lib/libcrosslayer.so
	else
		export LD_PRELOAD=/usr/lib/libnopred.so
	fi

	COMMAND="$APPPREFIX mpiexec -n $NPROC ./MADbench2_io $WORKLOAD 30 1 8 64 1 1 $RECORD $STRIDE $FLUSH"
	echo "$COMMAND"
	numactl --hardware &> $OUTPUT
	wait; sync
	$COMMAND &>> $OUTPUT
	export LD_PRELOAD=""
	wait; sync
	echo "*******************DMESG OUTPUT******************" >> $OUTPUT
	dmesg | grep -v -F "systemd-journald" >> $OUTPUT
	wait; sync

}


make clean; make -j ##Make MADBench
REFRESH

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

					RUNAPP $NPROC $WORKLOAD $PREDICT $READSIZE $PREFETCHTIMES
					REFRESH
					if [ "$PREDICT" -eq "0" ]; then
						break;
					fi
				done
			done
		done 
	done	
done

git add $RESULTS_FOLDER
message="results_at "
message+=$RIGHTNOW
git commit -m "$message"
git push
