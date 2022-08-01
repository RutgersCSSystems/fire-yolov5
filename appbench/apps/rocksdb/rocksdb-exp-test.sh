#!/bin/bash
set -x
DBHOME=$PWD
THREAD=4
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
DBDIR=$DBHOME/DATA

#WORKLOAD="readseq"
#WORKLOAD="readreverse"

WORKLOAD="readrandom"
WRITEARGS="--benchmarks=fillrandom --use_existing_db=0 --threads=2"
READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD"
#READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD --advise_random_on_open=false --readahead_size=2097152 --compaction_readahead_size=2097152 --log_readahead_size=2097152"
APPPREFIX="/usr/bin/time -v"

APP=db_bench
APPOUTPUTNAME="ROCKSDB"

RESULTS="RESULTS"/$WORKLOAD
RESULTFILE=""

mkdir -p $RESULTS



declare -a num_arr=("4000000")
NUM=4000000


declare -a workload_arr=("readrandom" "readseq" "readreverse" "compact" "overwrite" "readwhilewriting" "readwhilescanning")
#declare -a config_arr=("Vanilla" "Cross_Naive" "CPBI" "CPNI" "CNI" "CPBV" "CPNV")
#declare -a workload_arr=("readwhilescanning")
declare -a config_arr=("Vanilla" "Cross_Naive" "CPBI" "CPNI" "CNI" "CPBV" "CPNV")
declare -a thread_arr=("8" "16" "32")



FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo dmesg --clear
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



SETPRELOAD()
{
        if [[ "$1" == "VANILLA" ]]; then ##All three
                printf "setting Vanilla\n"
                #export LD_PRELOAD=/usr/lib/lib_Vanilla.so
                export LD_PRELOAD=/usr/lib/lib_Vanilla.so
        elif [[ "$1" == "OSONLY" ]]; then ##None
                printf "setting OSonly\n"
                export LD_PRELOAD=/usr/lib/lib_OSonly.so
        elif [[ "$1" == "CPNI" ]]; then
                export LD_PRELOAD=/usr/lib/lib_CPNI.so
        fi
}

COMPILE_AND_WRITE()
{
        export LD_PRELOAD=""
	PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --num=$NUM"
	mkdir -p $RESULTS

	cd $PREDICT_LIB_DIR
	$PREDICT_LIB_DIR/compile.sh &> compile.out
	cd $DBHOME
        #$DBHOME/db_bench $PARAMS $WRITEARGS &> $RESULTS/WARMUP-WRITE.out

        ##Condition the DB to get Stable results
        $DBHOME/db_bench $PARAMS $READARGS  &> $RESULTS/WARMUP-READ1.out
        FlushDisk
        #$DBHOME/db_bench $PARAMS $READARGS  &> WARMUP-READ2.out
}



GEN_RESULT_PATH() {
	WORKLOAD=$1
	CONFIG=$2
	THREAD=$3
	#WORKLOAD="DUMMY"
	#RESULTFILE=""
        RESULTS=$OUTPUTDIR/$APPOUTPUTNAME/$WORKLOAD/$THREAD
	mkdir -p $RESULTS
	RESULTFILE=$RESULTS/$CONFIG.out
}


RUN() {

        #CLEAR_DATA

	echo "BEGINNING TO WARM UP ......."
	COMPILE_AND_WRITE
	echo "FINISHING WARM UP ......."
	echo "..................................................."
	FlushDisk

	for NUM in "${num_arr[@]}"
	do
		for THREAD in "${thread_arr[@]}"
		do
			PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --num=$NUM"

			for CONFIG in "${config_arr[@]}"
			do
				for WORKLOAD in "${workload_arr[@]}"
				do
					RESULTS=""
					READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD"
					GEN_RESULT_PATH $WORKLOAD $CONFIG $THREAD

					mkdir -p $RESULTS

					echo "RUNNING $CONFIG and writing results to $RESULTS/$CONFIG.out"
					echo "..................................................."
					export LD_PRELOAD=/usr/lib/lib_$CONFIG.so
					$APPPREFIX "./"$APP $PARAMS $READARGS &> $RESULTFILE
					echo $RESULTFILE
					export LD_PRELOAD=""
					FlushDisk
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



#FIXME: This needs to be automated and looped instead of hardcoding similar to the RUN function
print_results() {
	echo "Vanilla Results"
	cat $RESULTS/VANILLA.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

	echo "CPNI Results"
	cat $RESULTS/CPNI.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

	echo "CNI Results"
	cat $RESULTS/CNI.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

	echo "CPBI Results"
	cat $RESULTS/CPBI.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

	echo "CPBV Results"
	cat $RESULTS/CPBV.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

	echo "CPNV Results"
	cat $RESULTS/CPNV.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

	echo "CROSS-NAIVE Results"
	cat $RESULTS/Cross_Naive.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."
}


