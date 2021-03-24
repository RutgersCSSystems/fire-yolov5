#!/bin/bash
#set -x

##prefetch window multiple factor 1, 2, 4
##grep the elapsed time, file faults, minor faults, system time, user time
APP="IOR"
APPDIR=$PWD
RESULTS_FOLDER=$OUTPUTDIR/$APP/results-sensitivity-sudarsun/noprep-threading
mkdir -p $RESULTS_FOLDER

cd $APPDIR

declare -a apparr=("ior")
declare -a predict=("0" "1")
declare -a thrdarr=("16" "32")

declare -a transfersizearr=("8192" "16384") #transfer size
declare -a blockprodarr=("100000" "150000" "200000") #blocksize = transfersize*blockprod
declare -a segmentarr=("1" "256" "1024" "2048") #segmentsize

declare -a thrdarr=("8")
declare -a transfersizearr=("16384") #transfer size
declare -a blockprodarr=("1000") #blocksize = transfersize*blockprod
declare -a segmentarr=("256") #segmentsize
declare -a predict=("1")
#sizeofprefetch = prefetchwindow * readsize
declare -a prefetchwindow=("8")
#declare -a prefetchwindow=("8")



#reduce the dirty files aggressively
$ENVPATH/set_disk_dirty.sh

#APPPREFIX="numactl --membind=0"
APPPREFIX=""
FILENAME=test_outfile_ior

COMPILE_SHAREDLIB() {
    cd $NVMBASE/shared_libs/pred
    make clean
    make -j16
    sudo make install
    cd $APPDIR

}

REFRESH() {
	$NVMBASE/scripts/compile-install/clear_cache.sh
	sudo sh -c "dmesg --clear" ##clear dmesg
	sleep 2
}

SYNCFILES() {

	OUTPUT=$1
	wait; sync
	echo "*******************DMESG OUTPUT******************" >> $OUTPUT
	dmesg | grep -v -F "systemd-journald" >> $OUTPUT
	wait; sync
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
	REORDER="-C"
	FILEPERPROC="-F"
	KEEPFILE="-k"

	#Unused
	MADVICE="--mmap.madv_dont_need" #Currently not used
	REORDERTASKRAND="-Z" #reorderTasksRandom -- changes task ordering to random ordering for readback

	OUTPUTDIR=$RESULTS_FOLDER/"BLKSIZE-"$BLOCKSIZE
	mkdir -p $OUTPUTDIR

	OUTPUT=$OUTPUTDIR/$APP"_PROC-"$NPROC"_PRED-"$PREDICT"_BLKSIZE-"$BLOCKSIZE"_TRANSFERSIZE-"$TRANSFER"_SEGMENTS-"$SEGMENT"_TIMESPFETCH-"$TPREFETCH".out"

	#echo "********** prepping File **************"
	PARAMS="-e -o $FILENAME -v -b $BLOCKSIZE -t $TRANSFER -s $SEGMENT $REORDER $FILEPERPROC $KEEPFILE"
	WRITE=" -w "
	READ=" -r "

	#echo "mpirun -np $NPROC ior $WRITE $PARAMS"
	#mpirun -np $NPROC ior $WRITE $PARAMS

	REFRESH

	export TIMESPREFETCH=$TPREFETCH
	APPPREFIX="/usr/bin/time -v"

	#echo "*********** running $OUTPUT ***********"
	if [[ "$PREDICT" == "1" ]]; then
		export LD_PRELOAD=/usr/lib/libcrosslayer.so
	else
		export LD_PRELOAD=/usr/lib/libnopred.so
	fi

	numactl --hardware &> $OUTPUT
	wait; sync

	if [[ "$APP" == "ior" ]]; then

		echo "$APPPREFIX mpirun -np $NPROC $READ $PARAMS"
		#$APPPREFIX mpirun -np $NPROC ior $READ $PARAMS &>> $OUTPUT
		$APPPREFIX mpirun -np $NPROC ior $PARAMS #&>> $OUTPUT
		#cat $OUTPUT | grep "Elapsed"

		export LD_PRELOAD=""
		REFRESH
		SYNCFILES $OUTPUT
	fi
}

COMPILE_SHAREDLIB
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
							#rm -rf $FILENAME*

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
