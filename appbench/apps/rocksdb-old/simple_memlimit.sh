#!/bin/bash

if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

DBHOME=$PWD
THREAD=4
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
NUM=1000000
DBDIR=$DBHOME/DATA

WORKLOAD="readseq"
#WORKLOAD="readrandom"
#WORKLOAD="readreverse"
WRITEARGS="--benchmarks=fillrandom --use_existing_db=0 --threads=1"
READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD"
#READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD --advise_random_on_open=false --readahead_size=2097152 --compaction_readahead_size=2097152 --log_readahead_size=2097152"
APPPREFIX="/usr/bin/time -v"

declare -a num_arr=("1000000")

umount_ext4ramdisk

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
        $DBHOME/db_bench $PARAMS $WRITEARGS
        FlushDisk

        ##Condition the DB to get Stable results
        $DBHOME/db_bench $PARAMS $READARGS 
        FlushDisk
        $DBHOME/db_bench $PARAMS $READARGS 
        FlushDisk
}

for NUM in "${num_arr[@]}"
do
        PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --num=$NUM"

        CLEAN_AND_WRITE
        FlushDisk

        printf "\nRUNNING Memlimit.................\n"
        #SETPRELOAD "VANILLA"
        export LD_PRELOAD=/usr/lib/lib_memusage.so
        $DBHOME/db_bench $PARAMS $READARGS
        export LD_PRELOAD=""
        FlushDisk

        anon=62
        cache=2424

        #total_anon_used=62 MB, total_cache=2833 MB

        exit

        free -h
        SETUPEXTRAM_1 `echo "scale=0; ($anon + ($cache * 0.4))/1" | bc --mathlib`
        free -h

        printf "\nRUNNING Vanilla.................\n"
        SETPRELOAD "VANILLA"
        $DBHOME/db_bench $PARAMS $READARGS
        export LD_PRELOAD=""
        FlushDisk

        printf "\nRUNNING CROSS_BLOCKRA_NOPRED_MAXMEM_BG................\n"
        SETPRELOAD "CBNMB"
        $DBHOME/db_bench $PARAMS $READARGS
        export LD_PRELOAD=""
        FlushDisk

        printf "\nRUNNING CROSS_BLOCKRA_NOPRED_BUDGET_BG................\n"
        SETPRELOAD "CBNBB"
        $DBHOME/db_bench $PARAMS $READARGS
        export LD_PRELOAD=""
        FlushDisk

        printf "\nRUNNING CROSS_BLOCKRA_PRED_MAXMEM_BG................\n"
        SETPRELOAD "CBPMB"
        $DBHOME/db_bench $PARAMS $READARGS
        export LD_PRELOAD=""
        FlushDisk

        printf "\nRUNNING CROSS_BLOCKRA_PRED_BUDGET_BG................\n"
        SETPRELOAD "CBPBB"
        $DBHOME/db_bench $PARAMS $READARGS
        export LD_PRELOAD=""
        FlushDisk

        umount_ext4ramdisk
done
