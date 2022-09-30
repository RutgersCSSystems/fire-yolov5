#!/bin/bash
#set -x
DBHOME=$PWD
PREDICT="OSONLY"
THREAD=32
SYNC=0
NUM=20000000
DBDIR=$DBHOME/checkpoint

APP="hacc_io_read"
APPNAME="hacc-io"
APPOUTPUTNAME="hacc-CR-shared"

APPREAD="mpiexec -n $THREAD ./hacc_io_read"
APPGEN="mpiexec -n $THREAD ./hacc_io_write"

PARAMS="$NUM $DBDIR"

mkdir -p $DBDIR


#indicates numiterations
declare -a num_arr=("20000000" "40000000" "10000000")
declare -a num_arr=("40000000")
declare -a thread_arr=("16" "8" "32" "4")
declare -a workload_arr=("restart")
declare -a config_arr=("OSonly" "Vanilla" "Cross_Info_sync" "Cross_Blind" "CII" "Cross_Info" "CIP" "CIPI" "CIPI_sync")
declare -a config_arr=("OSonly" "Vanilla" "Cross_Blind" "CII" "Cross_Info" "CIP" "CIPI")

declare -a config_arr=("CII" "CIP" "CIPI" "OSonly")
declare -a thread_arr=("16")


#Require for large database
ulimit -n 1000000 


if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi


BUILD_LIB()
{
        cd $SHARED_LIBS/pred
        ./compile.sh
        cd $DBHOME
}



FlushDisk()
{
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
}

CLEAR_DATA()
{
        sudo killall $APP
        sudo killall $APP
        sleep 3
        sudo killall $APP
}


RUNCACHESTAT()
{
	sudo $HOME/ssd/perf-tools/bin/cachestat &> "CACHESTAT-"$APPNAME"-"$PREDICT".out" &
}


#Run write workload twice
COMPILE_AND_WRITE() {

	cd $PREDICT_LIB_DIR
	$PREDICT_LIB_DIR/compile.sh
	cd $DBHOME

	APPGEN="mpiexec -n $THREAD ./hacc_io_write"
	$APPGEN $PARAMS

	echo "FINISHING WARM UP ......."
	echo "..................................................."
	FlushDisk
	sudo dmesg -c
}

GEN_RESULT_PATH() {
	WORKLOAD=$1
	CONFIG=$2
	THREAD=$3
	let NUM=$4
	let KEYNUM=$NUM/1000000
        RESULTS=$OUTPUTDIR/$APPOUTPUTNAME/$WORKLOAD/$KEYNUM"-M"/$THREAD
	mkdir -p $RESULTS
	RESULTFILE=$RESULTS/$CONFIG".out"
}


RUN() {

        CLEAR_DATA

	for NUM in "${num_arr[@]}"
	do
		for THREAD in "${thread_arr[@]}"
		do

			echo "BEGINNING TO WARM UP ......."
			#cd $PREDICT_LIB_DIR
			#$PREDICT_LIB_DIR/compile.sh
			#cd $DBHOME

			PARAMS="$NUM $DBDIR"
			COMPILE_AND_WRITE

			echo "FINISHING WARM UP ......."
			FlushDisk

			for CONFIG in "${config_arr[@]}"
			do
				for WORKLOAD in "${workload_arr[@]}"
				do
					RESULTS=""
					GEN_RESULT_PATH $WORKLOAD $CONFIG $THREAD $NUM

					mkdir -p $RESULTS
					echo "RUNNING $CONFIG and writing results to #$RESULTS/$CONFIG.out"
					mpiexec -n $THREAD -env LD_PRELOAD=/usr/lib/lib_$CONFIG.so ./hacc_io_read $NUM $DBDIR &> $RESULTFILE
					export LD_PRELOAD=""
					sudo dmesg -c &>> $RESULTFILE
					echo ".......FINISHING $CONFIG......................"
					cat $RESULTS/$CONFIG.out | grep "MB/s"
					FlushDisk
				done
			done
		done
	done
}

RUN
exit




