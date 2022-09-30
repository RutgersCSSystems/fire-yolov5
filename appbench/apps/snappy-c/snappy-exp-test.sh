#!/bin/bash
set -x
DBHOME=$PWD
THREAD=4
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864

WORKLOAD="snappy-threads"
APPPREFIX="/usr/bin/time -v"

APP="snappy"
APPOUTPUTNAME="snappy"

RESULTS="RESULTS"/$WORKLOAD
RESULTFILE=""

DBDIR=$SHARED_DATA/snappy
RESULTDIR=$SHARED_DATA/$APP/
FILECOUNT=100

let gen_data=$1

mkdir -p $RESULTS

#declare -a thread_arr=("4" "8" "16" "32")
#declare -a config_arr=("Vanilla" "Cross_Naive" "CPBI" "CNI" "CPBV" "CPNV" "CPNI")

declare -a thread_arr=("16")

#Number of files to compress
declare -a workload_arr=("200")

# Size of each file in KB
#declare -a filesize_arr=("30000" "20000" "10000")
declare -a filesize_arr=("100000" "200000")

FILESIZE=1000


declare -a config_arr=("Cross_Blind" "Cross_Info" "OSonly" "Vanilla" "Cross_Info_sync" "CII")
declare -a config_arr=("Cross_Info" "OSonly")
declare -a config_arr=("CIP" "CII" "CIPI" "OSonly")
declare -a config_arr=("Cross_Info" "Vanilla" "CIP" "CII" "CIPI" "OSonly")


FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        #sudo dmesg --clear
        sleep 2
}

CLEAR_DATA()
{
        sudo killall $APP
        sudo killall $APP
        sleep 3
        sudo killall $APP
        rm -rf $DBDIR/OUT*
}


GENDATA() {

        filesize=$1
	numfiles=$2
        threads=$3


        let file_perthread=$numfiles/$threads
        echo $file_perthread

        for (( t=1; t<=$threads; t++ ))
        do
                DIR=$DBDIR/$t

                mkdir -p $DIR
		cd $DIR
                echo $numfiles
                rm *
		cd $DBHOME
                $DBHOME/gen_file_posix $numfiles $filesize $DIR
        done
}


COMPILE_SHAREDLIB() {
        cd $PREDICT_LIB_DIR
        $PREDICT_LIB_DIR/compile.sh &> compile.out
        cd $DBHOME 
}

COMPILE_AND_WRITE()
{

        echo "..........BEGIN DATA GENERATION..............."
        export LD_PRELOAD=""
	mkdir -p $RESULTS

        filesize=$1
	numfiles=$2
        threads=$3

	COMPILE_SHAREDLIB

	#Generate data
	GENDATA $filesize $numfiles $threads
	sudo dmesg -c &> del.txt
	rm del.txt

        echo "..........END DATA GENERATION..............."
}

GEN_RESULT_PATH() {
	WORKPATH=$1
	CONFIG=$2
	THREAD=$3
	#WORKLOAD="DUMMY"
	#RESULTFILE=""
        RESULTS=$OUTPUTDIR/$APPOUTPUTNAME/$WORKPATH/$THREAD
	mkdir -p $RESULTS
	RESULTFILE=$RESULTS/$CONFIG.out
}



RUN() {

	COMPILE_SHAREDLIB

	#NUMFILES
	for WORKLOAD in "${workload_arr[@]}"
	do
		#FILESIZE represents file size in bytes
		for FILESIZE in "${filesize_arr[@]}"
		do
			for THREAD in "${thread_arr[@]}"
			do
				PARAMS="$DBDIR $THREAD"

				if [ $gen_data -gt 0 ]
				then
				    echo "GENERATING NEW DATA"
				    COMPILE_AND_WRITE $FILESIZE $WORKLOAD $THREAD
				fi

				for CONFIG in "${config_arr[@]}"
				do
					FlushDisk

					RESULTS=""
					GEN_RESULT_PATH "fsize-"$FILESIZE $CONFIG $THREAD

					mkdir -p $RESULTS

					echo "RUNNING $CONFIG and writing results to #$RESULTS/$CONFIG.out"
					echo "..................................................."
					#export LD_PRELOAD=/usr/lib/lib_$CONFIG.so
					echo "$APPPREFIX $DBHOME/$APP $PARAMS"
					#$APPPREFIX 
					LD_PRELOAD=/usr/lib/lib_$CONFIG.so $DBHOME/$APP $PARAMS  &> $RESULTFILE
					export LD_PRELOAD=""
					sudo dmesg -c &>> $RESULTFILE
					echo ".......FINISHING $CONFIG......................"
					FlushDisk
				done
			done
		done
	done
}

RUN
#CLEAR_DATA
exit

