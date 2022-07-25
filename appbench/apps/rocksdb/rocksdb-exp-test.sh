#!/bin/bash
DBHOME=$PWD
THREAD=4
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
NUM=10000000
DBDIR=$DBHOME/DATA

#WORKLOAD="readseq"
WORKLOAD="readrandom"
#WORKLOAD="readreverse"
WRITEARGS="--benchmarks=fillrandom --use_existing_db=0 --threads=1"
READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD"
#READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD --advise_random_on_open=false --readahead_size=2097152 --compaction_readahead_size=2097152 --log_readahead_size=2097152"
APPPREFIX="/usr/bin/time -v"
RESULTS="RESULTS"/$WORKLOAD

APP=db_bench
APPOUTPUTNAME="ROCKSDB"

mkdir -p $RESULTS


declare -a num_arr=("4000000")
#declare -a workload_arr=("readrandom" "readseq" "readreverse" "compact" "overwrite" "readwhilewriting" "readwhilescanning")
declare -a workload_arr=("readwhilescanning")
declare -a config_arr=("Vanilla" "Cross_Naive" "CPBI" "CPNI" "CNI" "CPBV" "CPNV")


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

CLEAR_PWD()
{
        cd $DBDIR
        rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
        cd ..
}


CLEAN_AND_WRITE()
{
        #printf "in ${FUNCNAME[0]}\n"
        export LD_PRELOAD=""
        CLEAR_PWD
        $DBHOME/db_bench $PARAMS $WRITEARGS &> $RESULTS/WARMUP-WRITE.out
        #FlushDisk

        ##Condition the DB to get Stable results
        $DBHOME/db_bench $PARAMS $READARGS  &> $RESULTS/WARMUP-READ1.out
        FlushDisk
        #$DBHOME/db_bench $PARAMS $READARGS  &> WARMUP-READ2.out
        #FlushDisk
}

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


RUN() {

	for NUM in "${num_arr[@]}"
	do
		PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --num=$NUM"

		mkdir -p $RESULTS
		echo "BEGINNING TO WARM UP ......."
		CLEAN_AND_WRITE
		echo "FINISHING WARM UP ......."
		echo "..................................................."
		FlushDisk

		for CONFIG in "${config_arr[@]}"
		do
			for WORKLOAD in "${workload_arr[@]}"
			do
				RESULTS=""
				READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD"
				RESULTS=$OUTPUTDIR/$APPOUTPUTNAME/$WORKLOAD

				mkdir -p $RESULTS

				echo "RUNNING $CONFIG and writing results to $RESULTS/$CONFIG.out....."
				echo "..................................................."
				export LD_PRELOAD=/usr/lib/lib_$CONFIG.so
				$APPPREFIX "./"$APP $PARAMS $READARGS &> $RESULTS/$CONFIG.out
				export LD_PRELOAD=""
				FlushDisk
				echo ".......FINISHING $CONFIG......................"
				FlushDisk
			done
		done
	done
}

RUN
CLEAR_DATA
exit
