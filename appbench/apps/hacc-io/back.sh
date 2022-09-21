#!/bin/bash
set -x
DBHOME=$PWD
DBDIR=$DBHOME/$DATA
#DBDIR=/mnt/remote/DATA

APP=$APPBASE/pagerank
APPPREFIX="/usr/bin/time -v"


APPOUTPUTNAME="graphchi"
RESULTS="RESULTS"/$WORKLOAD
RESULTFILE=""

sudo chown -R $USER $DBDIR
mkdir -p $RESULTS

cd $APPBENCH/apps/graphchi

#indicates numiterations
declare -a num_arr=("1")
declare -a thread_arr=("32")
declare -a workload_arr=("pagerank")
declare -a config_arr=("OSonly" "Vanilla" "Cross_Info_sync" "Cross_Blind" "CII" "Cross_Info")

declare -a config_arr=("OSonly" "Vanilla" "Cross_Info_sync" "Cross_Blind" "CII")
declare -a config_arr=("Cross_Info_sync" "Cross_Blind" "CII")



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
        #sudo dmesg --clear
        sleep 5
}

CLEAR_DATA()
{
        sudo killall $APP
        sudo killall $APP
        sleep 3
        sudo killall $APP
}

COMPILE_AND_WRITE()
{
        export LD_PRELOAD=""
	mkdir -p $RESULTS
	cd $PREDICT_LIB_DIR
	$PREDICT_LIB_DIR/compile.sh &> compile.out
}



GEN_RESULT_PATH() {
	WORKLOAD=$1
	CONFIG=$2
	THREAD=$3
	let NUM=$4
	let KEYNUM=$NUM/1000000
        RESULTS=$OUTPUTDIR/$APPOUTPUTNAME/$WORKLOAD/$THREAD
	mkdir -p $RESULTS
	RESULTFILE=$RESULTS/$CONFIG"-preprocess.out"
}


RUN() {

        #CLEAR_DATA

	echo "BEGINNING TO WARM UP ......."
	cd $PREDICT_LIB_DIR
	$PREDICT_LIB_DIR/compile.sh
	cd $DBHOME
	#COMPILE_AND_WRITE
	echo "FINISHING WARM UP ......."
	echo "..................................................."
	FlushDisk
	sudo dmesg -c

	for NUM in "${num_arr[@]}"
	do
		for THREAD in "${thread_arr[@]}"
		do
			for CONFIG in "${config_arr[@]}"
			do
				for WORKLOAD in "${workload_arr[@]}"
				do
					RESULTS=""
					GEN_RESULT_PATH $WORKLOAD $CONFIG $THREAD $NUM

					mkdir -p $RESULTS

					echo rm -rf $DBDIR".*"
					rm -rf $DBDIR".*"
					rm -rf $DBDIR"_degs.bin"


					echo "RUNNING $CONFIG and writing results to #$RESULTS/$CONFIG.out"
					echo "..................................................."
					export LD_PRELOAD=/usr/lib/lib_$CONFIG.so
					echo "edgelist" | $APPPREFIX $APP file $DBDIR niters $NUM  &> $RESULTFILE
					export LD_PRELOAD=""
					sudo dmesg -c &>> $RESULTFILE
					echo ".......FINISHING $CONFIG......................"
					cat $RESULTS/$CONFIG.out | grep "runtime"
					FlushDisk
				done
			done
		done
	done
}

RUN
exit

