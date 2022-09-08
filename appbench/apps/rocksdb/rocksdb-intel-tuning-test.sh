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

source $RUN_SCRIPTS/generic_funcs.sh


if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi


#WORKLOAD="readseq"
#WORKLOAD="readreverse"

WORKLOAD="readrandom"

#WRITEARGS="--benchmarks=fillseq --use_existing_db=0 --threads=1"
WRITEARGS="
--benchmarks=fillseq \
--use_existing_db=0 \
--db=$DBDIR \
--wal_dir=$DBDIR/WAL_LOG\
--key_size=20 \
--value_size=400 \
--num=240000000 \
--threads=1 \
--max_background_jobs=12 \
--block_size=4096 \
--write_buffer_size=1073741824 \
--arena_block_size=16777216 \
--max_write_buffer_number=50 \
--memtablerep=vector \
--allow_concurrent_memtable_write=false \
--cache_size=0 \
--batch_size=4 \
--bloom_bits=10 \
--target_file_size_base=1073741824 \
--max_bytes_for_level_base=10737418240 \
--max_bytes_for_level_multiplier=10 \
--level0_file_num_compaction_trigger=10000 \
--level0_slowdown_writes_trigger=1048576000 \
--level0_stop_writes_trigger=1048576000 \
--soft_pending_compaction_bytes_limit=274877906944 \
--hard_pending_compaction_bytes_limit=549755813888 \
--use_direct_reads=0 --use_direct_io_for_flush_and_compaction=0 \
--disable_wal=1 --verify_checksum=1 \
--stats_per_interval=1 --stats_interval_seconds=60 --histogram=1"


READARGS="--benchmarks=readrandom \
--mmap_read=0 
--disable_auto_compactions=1 \
--use_existing_db=1 \
--db=$DBDIR \
--wal_dir=$DBDIR/WAL_LOG\
--key_size=20 \
--value_size=400 \
--num=240000000 \
--threads=40 \
--block_size=4096 \
--cache_size=17179869184 \
--cache_numshardbits=10 \
--arena_block_size=16777216 \
--memtablerep=skip_list \
--bloom_bits=10 \
--use_direct_reads=0 \
--use_direct_io_for_flush_and_compaction=0 \
--verify_checksum=1 \
--seed=1576170874 \
--stats_per_interval=1 \
--stats_interval_seconds=60 \
--histogram=1"



#READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD --advise_random_on_open=false --readahead_size=2097152 --compaction_readahead_size=2097152 --log_readahead_size=2097152"
APPPREFIX="/usr/bin/time -v"

APP=db_bench
APPOUTPUTNAME="ROCKSDB-intel-40GB"

RESULTS="RESULTS"/$WORKLOAD
RESULTFILE=""

mkdir -p $RESULTS



declare -a num_arr=("2000000")
NUM=2000000

#declare -a workload_arr=("readrandom" "readseq" "readreverse" "compact" "overwrite" "readwhilewriting" "readwhilescanning")
#declare -a thread_arr=("4" "8" "16" "32")
#declare -a config_arr=("Vanilla" "Cross_Naive" "CPBI" "CNI" "CPBV" "CPNV" "CPNI")

declare -a thread_arr=("40")

#declare -a workload_arr=("readseq" "readrandom" "readwhilescanning")
declare -a workload_arr=("readrandom")
declare -a config_arr=("OSonly")
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
	#PARAMS="--db=$DBDIR"
	mkdir -p $RESULTS

	#cd $PREDICT_LIB_DIR
	#$PREDICT_LIB_DIR/compile.sh &> compile.out
	cd $DBHOME
        $DBHOME/db_bench $WRITEARGS #&> $RESULTS/WARMUP-WRITE.out

        ##Condition the DB to get Stable results
        #$DBHOME/db_bench $READARGS  #&> $RESULTS/WARMUP-READ1.out
        #FlushDisk
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
					GEN_RESULT_PATH $WORKLOAD $CONFIG $THREAD

					mkdir -p $RESULTS

                                        SETUPEXTRAM_1 `echo "scale=0; 40*$GB" | bc --mathlib`
					echo "RUNNING $CONFIG and writing results to #$RESULTS/$CONFIG.out"
					echo "..................................................."
					export LD_PRELOAD=/usr/lib/lib_$CONFIG.so
					$APPPREFIX "./"$APP $READARGS &> $RESULTFILE
					export LD_PRELOAD=""
					sudo dmesg -c &>> $RESULTFILE
					echo ".......FINISHING $CONFIG......................"
                                        umount_ext4ramdisk
					FlushDisk
				done
			done
		done
	done
}

umount_ext4ramdisk
RUN
umount_ext4ramdisk
#CLEAR_DATA
exit
