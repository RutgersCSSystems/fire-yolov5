#!/bin/bash
#set -x

if [ -z "$NVMBASE" ]; then
	echo "NVMBASE environment variable not defined. Have you ran setvars?"
	exit 1
fi

##prefetch window multiple factor 1, 2, 4
##grep the elapsed time, file faults, minor faults, system time, user time

RIGHTNOW=`date +"%H-%M_%m-%d-%y"`
APP="IOR"
APPDIR=$PWD
RESULTS_FOLDER=$OUTPUTDIR/$APP/results-sensitivity-$RIGHTNOW
mkdir -p $RESULTS_FOLDER

cd $APPDIR

declare -a predict=("0")
declare -a thrdarr=("16")
declare -a transfersizearr=("8192" "16384") #transfer size
declare -a blockprodarr=("100000" "150000") #blocksize = transfersize*blockprod
declare -a segmentarr=("1" "256" ) #segmentsize
#sizeofprefetch = prefetchwindow * readsize
declare -a prefetchwindow=("1" "2" "4")

#APPPREFIX="numactl --membind=0"
APPPREFIX=""
FILENAME=test_outfile_ior

VTUNE_ENABLE=1
AMPLXE=/opt/intel/vtune_amplifier_2019/bin64/amplxe-cl
CONFIG_AMPLXE="-trace-mpi -collect hotspots -k enable-stack-collection=true -k stack-size=0 -k sampling-mode=hw"

REFRESH() {
	$NVMBASE/scripts/compile-install/clear_cache.sh
	sudo sh -c "dmesg --clear" ##clear dmesg
	sleep 2
}

#Here is where we run the application
RUNAPP() {
	echo "**********RUNAPP**********"
	#Run application
	cd $APPDIR

	NPROC=$1
	PREDICT=$2
	SEGMENT=$3
	TRANSFER=$4
	BLOCKTIMES=$5
	BLOCKSIZE=`echo "$TRANSFER * $BLOCKTIMES" | bc`
	TPREFETCH=$6

	OUTPUT=$RESULTS_FOLDER/$APP"_PROC-"$NPROC"_PRED-"$PREDICT"_BLKSIZE-"$BLOCKSIZE"_TRANSFERSIZE-"$TRANSFER"_SEGMENTS-"$SEGMENT"_TIMESPFETCH-"$TPREFETCH".out"

	echo "********** prepping File **************"
	echo "mpirun -np $NPROC ior -w -k -e -o $FILENAME -v -b $BLOCKSIZE -t $TRANSFER -s $SEGMENT"
	mpirun -np $NPROC ior -w -F -k -e -o $FILENAME -v -b $BLOCKSIZE -t $TRANSFER -s $SEGMENT

	REFRESH

	export TIMESPREFETCH=$TPREFETCH
	APPPREFIX="/usr/bin/time -v"
	VTUNE_TRACE=""
	if [[ "$VTUNE_ENABLE" == "1" ]]; then
		VTUNE_ROOT=$RESULTS_FOLDER/vtune
		VTUNE_RESULT="vtune_"$APP"_PROC-"$NPROC"_PRED-"$PREDICT"_LOAD-"$WORKLOAD"_READSIZE-"$RECORD"_TIMESPFETCH-"$TPREFETCH
		VTUNE_TRACE="${AMPLXE} ${CONFIG_AMPLXE} -r $VTUNE_ROOT/$VTUNE_RESULT --"
		APPPREFIX=""
		mkdir $VTUNE_ROOT
	fi

	echo "*********** running $OUTPUT ***********"
	if [[ "$PREDICT" == "1" ]]; then
		export LD_PRELOAD=/usr/lib/libcrosslayer.so
	else
		export LD_PRELOAD=""
	fi


	if [[ "$APP" == "ior" ]]; then
		rm -rf $OUTPUT
		echo "$APPPREFIX mpirun -np $NPROC $VTUNE_TRACE ior -r -F -o $FILENAME -v -b $BLOCKSIZE -t $TRANSFER -s $SEGMENT"
		numactl --hard &> $OUTPUT
		wait; sync
		$APPPREFIX mpirun -np $NPROC $VTUNE_TRACE ior -r -F -o $FILENAME -v -b $BLOCKSIZE -t $TRANSFER -s $SEGMENT &>> $OUTPUT
		export LD_PRELOAD=""

		REFRESH

		wait; sync
		echo "*******************DMESG OUTPUT******************" >> $OUTPUT
		dmesg | grep -v -F "systemd-journald" >> $OUTPUT
		wait; sync
	fi
}


REFRESH

	for NPROC in "${thrdarr[@]}"
	do	
		for BLOCKPROD in "${blockprodarr[@]}"
		do
			for TRANSFERSIZE in "${transfersizearr[@]}"
			do
				for SEGMENT in "${segmentarr[@]}"
				do
					for PREDICT in "${predict[@]}"
					do 
						for PREFETCHTIMES in "${prefetchwindow[@]}"
						do 

							RUNAPP $NPROC $PREDICT $SEGMENT $TRANSFERSIZE $BLOCKPROD $PREFETCHTIMES
							REFRESH
							rm -rf $FILENAME*
							if [ "$PREDICT" -eq "0" ]; then
								break;
							fi
						done
					done
				done
			done 
		done	
	done
##IMplement the per proc bg thread
