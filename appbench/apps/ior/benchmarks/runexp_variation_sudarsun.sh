#!/bin/bash
#set -x

##prefetch window multiple factor 1, 2, 4
##grep the elapsed time, file faults, minor faults, system time, user time

APPDIR=$PWD
RESULTS_FOLDER=results-sensitivity-sudarsun

mkdir $RESULTS_FOLDER

cd $APPDIR

declare -a apparr=("ior")
declare -a predict=("0" "1")
declare -a thrdarr=("16" "32")

declare -a transfersizearr=("8192" "16384") #transfer size
declare -a blockprodarr=("100000" "150000" "200000") #blocksize = transfersize*blockprod
declare -a segmentarr=("1" "256" "1024" "2048") #segmentsize


declare -a transfersizearr=("16384") #transfer size
declare -a blockprodarr=("100000") #blocksize = transfersize*blockprod
declare -a segmentarr=("1") #segmentsize


#sizeofprefetch = prefetchwindow * readsize
declare -a prefetchwindow=("1" "2" "4")

#APPPREFIX="numactl --membind=0"
APPPREFIX=""
FILENAME=test_outfile_ior

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
	APP=$2
	PREDICT=$3
	SEGMENT=$4
	TRANSFER=$5
	BLOCKTIMES=$6
	BLOCKSIZE=`echo "$TRANSFER * $BLOCKTIMES" | bc`
	TPREFETCH=$7

	OUTPUT=$RESULTS_FOLDER/$APP"_PROC-"$NPROC"_PRED-"$PREDICT"_BLKSIZE-"$BLOCKSIZE"_TRANSFERSIZE-"$TRANSFER"_SEGMENTS-"$SEGMENT"_TIMESPFETCH-"$TPREFETCH".out"

	echo "********** prepping File **************"
	echo "mpirun -np $NPROC ior -w -k -e -o $FILENAME -v -b $BLOCKSIZE -t $TRANSFER -s $SEGMENT"
	mpirun -np $NPROC ior -w -F -k -e -o $FILENAME -v -b $BLOCKSIZE -t $TRANSFER -s $SEGMENT

	REFRESH

	export TIMESPREFETCH=$TPREFETCH
	APPPREFIX="/usr/bin/time -v"

	echo "*********** running $OUTPUT ***********"
	if [[ "$PREDICT" == "1" ]]; then
		export LD_PRELOAD=/usr/lib/libcrosslayer.so
	else
		export LD_PRELOAD=/usr/lib/libnopred.so
	fi


	if [[ "$APP" == "ior" ]]; then
		rm -rf $OUTPUT
		echo "$APPPREFIX mpirun -np $NPROC ior -r -F -o $FILENAME -v -b $BLOCKSIZE -t $TRANSFER -s $SEGMENT"
		numactl --hardware &> $OUTPUT
		wait; sync
		$APPPREFIX mpirun -np $NPROC ior -r -F -o $FILENAME -v -b $BLOCKSIZE -t $TRANSFER -s $SEGMENT &>> $OUTPUT
		export LD_PRELOAD=""

		REFRESH

		wait; sync
		echo "*******************DMESG OUTPUT******************" >> $OUTPUT
		dmesg | grep -v -F "systemd-journald" >> $OUTPUT
		wait; sync
	fi
}


REFRESH

for APP in "${apparr[@]}"
do
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
							RUNAPP $NPROC $APP $PREDICT $SEGMENT $TRANSFERSIZE $BLOCKPROD $PREFETCHTIMES
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
done
##IMplement the per proc bg thread
