#!/bin/bash
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
READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD --advise_random_on_open=false"
#READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD --advise_random_on_open=false --readahead_size=2097152 --compaction_readahead_size=2097152 --log_readahead_size=2097152"
APPPREFIX="/usr/bin/time -v"

declare -a num_arr=("1000000" "20000000" "30000000")

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
    if [[ "$1" == "APPLIBOS" ]]; then ##All three
        printf "setting pred\n"
        export LD_PRELOAD=/usr/lib/libcrosslayer.so
    elif [[ "$1" == "NOPRED" ]]; then ##None
        printf "setting nopred\n"
        export LD_PRELOAD=/usr/lib/libnopred.so
    elif [[ "$1" == "ONLYAPP" ]]; then
        printf "only app pred\n"
        export LD_PRELOAD=/usr/lib/libonlyapppred.so
    elif [[ "$1" == "ONLYLIB" ]]; then
        printf "only Lib pred\n"
        export LD_PRELOAD=/usr/lib/libonlylibpred.so
    elif [[ "$1" == "ONLYOS" ]]; then
        printf "only OS pred\n"
        export LD_PRELOAD=/usr/lib/libonlyospred.so
    elif [[ "$1" == "APPOS" ]]; then
        printf "App+OS pred\n"
        export LD_PRELOAD=/usr/lib/libos_apppred.so
    elif [[ "$1" == "LIBOS" ]]; then
        printf "Lib+OS pred\n"
        export LD_PRELOAD=/usr/lib/libos_libpred.so
    elif [[ "$1" == "ONLYINTERCEPT" ]]; then
        printf "Only Intercepting\n"
        export LD_PRELOAD=/usr/lib/libonlyintercept.so
    elif [[ "$1" == "CACHELIMIT" ]]; then
        printf "OS and LIB pred with Cache Limit\n"
        export LD_PRELOAD=/usr/lib/libcache_lim_os_libpred.so
    elif [[ "$1" == "FETCHALL" ]]; then
        printf "OS and LIB pred without Cache Limit\n"
        export LD_PRELOAD=/usr/lib/libos_fetch_at_open.so
    elif [[ "$1" == "FETCHALLSINGLE" ]]; then
        printf "OS and LIB pred without Cache Limit\n"
        export LD_PRELOAD=/usr/lib/libos_fetch_at_open_single.so
    elif [[ "$1" == "SIMPLEBGPREFETCH" ]]; then
        printf "Simple BG prefetcher\n"
        export LD_PRELOAD=/usr/lib/libsimpleprefetcher.so
    elif [[ "$1" == "SIMPLENOPREFETCH" ]]; then
        printf "Simple NO prefetcher\n"
        export LD_PRELOAD=/usr/lib/libsimplenoprefetcher.so
    elif [[ "$1" == "SIMPLEBGFULLPREFETCH" ]]; then
        printf "Simple BG FULL prefetcher\n"
        export LD_PRELOAD=/usr/lib/libsmpl_fullprefetcher.so
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
    $DBHOME/db_bench $PARAMS $WRITEARGS
    FlushDisk

    ##Condition the DB to get Stable results
    $DBHOME/db_bench $1 $READARGS 
    FlushDisk
    $DBHOME/db_bench $1 $READARGS 
    FlushDisk
}


for NUM in "${num_arr[@]}"
do
    PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --num=$NUM"

    CLEAN_AND_WRITE
    FlushDisk

    printf "\nRUNNING Vanilla.................\n"
    LD_PRELOAD=""
    $DBHOME/db_bench $PARAMS $READARGS
    FlushDisk

    printf "\nRUNNING Disable FADV_RANDOM .................\n"
    SETPRELOAD "SIMPLENOPREFETCH"
    $DBHOME/db_bench $PARAMS $READARGS
    LD_PRELOAD=""
    FlushDisk

    printf "\nRUNNING SIMPLE PREFETCHER .................\n"
    SETPRELOAD "SIMPLEBGPREFETCH"
    $DBHOME/db_bench $PARAMS $READARGS
    LD_PRELOAD=""
    FlushDisk

    printf "\nRUNNING SIMPLE FULL PREFETCHER .................\n"
    SETPRELOAD "SIMPLEBGFULLPREFETCH"
    $DBHOME/db_bench $PARAMS $READARGS
    LD_PRELOAD=""
    FlushDisk

    exit

done

