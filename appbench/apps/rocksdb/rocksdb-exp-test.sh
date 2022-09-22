#!/bin/bash
set -x
DBHOME=$PWD
THREAD=16
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
DBDIR=$DBHOME/DATA
#DBDIR=/mnt/remote/DATA


if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi


#WORKLOAD="readseq"
#WORKLOAD="readreverse"

WORKLOAD="readrandom"
WRITEARGS="--benchmarks=fillseq --use_existing_db=0 --threads=1"
READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD"
#READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD --advise_random_on_open=false --readahead_size=2097152 --compaction_readahead_size=2097152 --log_readahead_size=2097152"
APPPREFIX="/usr/bin/time -v"

APP=db_bench
APPOUTPUTNAME="ROCKSDB"

RESULTS="RESULTS"/$WORKLOAD
RESULTFILE=""

mkdir -p $RESULTS



declare -a num_arr=("20000000")
NUM=20000000

#declare -a workload_arr=("readrandom" "readseq" "readreverse" "compact" "overwrite" "readwhilewriting" "readwhilescanning")
#declare -a thread_arr=("4" "8" "16" "32")
#declare -a config_arr=("Vanilla" "Cross_Naive" "CPBI" "CNI" "CPBV" "CPNV" "CPNI")

#declare -a thread_arr=("1" "4" "8" "16")
#declare -a thread_arr=("16" "32" "8")
declare -a thread_arr=("16")


declare -a workload_arr=("readseq" "readrandom" "readwhilescanning" "readreverse" "multireadrandom")

USEDB=0
echo "CAUTION, CAUTION, USE EXITING DB is set to 0 for write workload testing!!!"
echo "CAUTION, CAUTION, USE EXITING DB is set to 0 for write workload testing!!"
echo "CAUTION, CAUTION, USE EXITING DB is set to 0 for write workload testing!!!"
echo "CAUTION, CAUTION, USE EXITING DB is set to 0 for write workload testing!!!"

declare -a workload_arr=("fillseq" "fillrandom")
declare -a config_arr=("Cross_Info" "OSonly" "Vanilla" "Cross_Info_sync" "Cross_Blind" "CII" "CIP" "CIP_sync")
#declare -a workload_arr=("multireadrandom")

#declare -a config_arr=("OSonly")
#declare -a config_arr=("Cross_Info")
#declare -a config_arr=("CIP" "CIP_sync")
#declare -a config_arr=("Cross_Info_sync")
#USEDB=1
#declare -a config_arr=( "CIPI_sync")


#declare -a config_arr=("Cross_Naive" "CNI" "CPNI")


#Require for large database
ulimit -n 1000000 


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
        rm -rf $DBDIR/*
        rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
}



COMPILE_AND_WRITE()
{
        export LD_PRELOAD=""
	PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --num=$NUM --target_file_size_base=209715200"
	mkdir -p $RESULTS

	cd $PREDICT_LIB_DIR
	$PREDICT_LIB_DIR/compile.sh &> compile.out
	cd $DBHOME
        $DBHOME/db_bench $PARAMS $WRITEARGS #&> $RESULTS/WARMUP-WRITE.out

        ##Condition the DB to get Stable results
        #$DBHOME/db_bench $PARAMS $READARGS  #&> $RESULTS/WARMUP-READ1.out
        #FlushDisk
        #$DBHOME/db_bench $PARAMS $READARGS  &> WARMUP-READ2.out
}



GEN_RESULT_PATH() {
	WORKLOAD=$1
	CONFIG=$2
	THREAD=$3
	let NUM=$4/1000000
	#WORKLOAD="DUMMY"
	#RESULTFILE=""
        RESULTS=$OUTPUTDIR/$APPOUTPUTNAME/$NUM"M-KEYS"/$WORKLOAD/$THREAD
	mkdir -p $RESULTS
	RESULTFILE=$RESULTS/$CONFIG.out
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
			PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --num=$NUM  --seed=1576170874"

			for WORKLOAD in "${workload_arr[@]}"
			do
				for CONFIG in "${config_arr[@]}"
				do
					RESULTS=""
					READARGS="--benchmarks=$WORKLOAD --use_existing_db=$USEDB --mmap_read=0 --threads=$THREAD"
					GEN_RESULT_PATH $WORKLOAD $CONFIG $THREAD $NUM

					mkdir -p $RESULTS

					echo "RUNNING $CONFIG and writing results to #$RESULTS/$CONFIG.out"
					echo "..................................................."
					export LD_PRELOAD=/usr/lib/lib_$CONFIG.so
					$APPPREFIX "./"$APP $PARAMS $READARGS &> $RESULTFILE
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
#CLEAR_DATA
exit

