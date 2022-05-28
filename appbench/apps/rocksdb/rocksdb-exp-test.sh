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

mkdir -p $RESULTS

declare -a num_arr=("10000000")

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo dmesg --clear
        sleep 5
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

        ##export TARGET_GPPID=$PPID
}

CLEAR_PWD()
{
        cd $DBDIR
        rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
        cd ..
}


CLEAN_AND_WRITE()
{
        printf "in ${FUNCNAME[0]}\n"

        export LD_PRELOAD=""
        CLEAR_PWD
        $DBHOME/db_bench $PARAMS $WRITEARGS &> $RESULTS/WARMUP-WRITE.out
        FlushDisk

        ##Condition the DB to get Stable results
        $DBHOME/db_bench $PARAMS $READARGS  &> $RESULTS/WARMUP-READ1.out
        FlushDisk
        $DBHOME/db_bench $PARAMS $READARGS  &> WARMUP-READ2.out
        FlushDisk
}

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

		echo "BEGINNING TO WARM UP ......."
		CLEAN_AND_WRITE
		FlushDisk
		printf "\n FINISHING WARM UP ......."
		print "\n .................\n"
		print "\n .................\n"
		print "\n .................\n"

		FlushDisk
		FlushDisk

		echo "RUNNING Vanilla.................\n"
		#SETPRELOAD "VANILLA"
		$DBHOME/db_bench $PARAMS $READARGS  &> $RESULTS/VANILLA.out
		export LD_PRELOAD=""
		echo "................."
		echo "................."
		FlushDisk


		printf "\nRUNNING CPNI.................\n"
		export LD_PRELOAD=/usr/lib/lib_CPNI.so
		$DBHOME/db_bench $PARAMS $READARGS &> $RESULTS/CPNI.out
		export LD_PRELOAD=""
		echo "................."
		echo "................."
		FlushDisk

		echo "RUNNING CNI.............\n"
		export LD_PRELOAD=/usr/lib/lib_CNI.so
		$DBHOME/db_bench $PARAMS $READARGS &> $RESULTS/CNI.out
		export LD_PRELOAD=""
		FlushDisk
		echo "................."
		echo "................."
		FlushDisk

		echo "RUNNING CPBI.............\n"
		export LD_PRELOAD=/usr/lib/lib_CPBI.so
		$DBHOME/db_bench $PARAMS $READARGS &> $RESULTS/CPBI.out
		export LD_PRELOAD=""
		FlushDisk
		echo "................."
		echo "................."
		FlushDisk

		echo "RUNNING CPBV.............\n"
		export LD_PRELOAD=/usr/lib/lib_CPBV.so
		$DBHOME/db_bench $PARAMS $READARGS &> $RESULTS/CPBV.out
		export LD_PRELOAD=""
		FlushDisk
		echo "................."
		echo "................."
		FlushDisk


		echo "RUNNING CPNV.............\n"
		export LD_PRELOAD=/usr/lib/lib_CPNV.so 
		$DBHOME/db_bench $PARAMS $READARGS &> $RESULTS/CPNV.out
		export LD_PRELOAD=""
		FlushDisk
		echo "................."
		echo "................."
		FlushDisk

		echo "RUNNING Cross Naive.............\n"
		export LD_PRELOAD=/usr/lib/lib_Cross_Naive.so 
		$DBHOME/db_bench $PARAMS $READARGS &> $RESULTS/Cross_Naive.out
		export LD_PRELOAD=""
		FlushDisk
		echo "................."
		echo "................."
		FlushDisk
	done
}

RUN
print_results
