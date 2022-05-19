#!/bin/bash
DBHOME=$PWD
THREAD=4
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
NUM=1000000
DBDIR=$DBHOME/DATA

DEV=/dev/nvme0n1p1

BLOCK_SZ=512 #Bytes
RA_SIZE=128 #KB

NR_RA_BLOCKS=`echo "($RA_SIZE*1024)/$BLOCK_SZ" | bc`

KB=1024
MB=`echo "1024*$KB" | bc`
GB=`echo "1024*$MB" | bc`

#sudo blockdev --setra $NR_RA_BLOCKS $DEV

WORKLOAD="readseq"
#WORKLOAD="readrandom"
#WORKLOAD="readreverse"
WRITEARGS="--benchmarks=fillrandom --use_existing_db=0 --threads=1"
READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD"
#READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD --advise_random_on_open=false"
#READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD --advise_random_on_open=false --readahead_size=2097152 --compaction_readahead_size=2097152 --log_readahead_size=2097152"
APPPREFIX="/usr/bin/time -v"

PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --num=$NUM"

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    #sudo dmesg --clear
}


ENABLE_LOCK_STATS()
{
	sudo sh -c "echo 0 > /proc/lock_stat"
	#sudo sh -c "echo 1 > /proc/sys/kernel/lock_stat"
}

DISABLE_LOCK_STATS()
{
	sudo sh -c "echo 0 > /proc/sys/kernel/lock_stat"
}


SETPRELOAD()
{
    if [[ "$1" == "APPLIBOS" ]]; then ##All three
        echo "setting pred"
        export LD_PRELOAD=/usr/lib/libcrosslayer.so
    elif [[ "$1" == "NOPRED" ]]; then ##None
        echo "setting nopred"
        export LD_PRELOAD=/usr/lib/libnopred.so
    elif [[ "$1" == "ONLYAPP" ]]; then
        echo "only app pred"
        export LD_PRELOAD=/usr/lib/libonlyapppred.so
    elif [[ "$1" == "ONLYLIB" ]]; then
        echo "only Lib pred"
        export LD_PRELOAD=/usr/lib/libonlylibpred.so
    elif [[ "$1" == "ONLYOS" ]]; then
        echo "only OS pred"
        export LD_PRELOAD=/usr/lib/libonlyospred.so
    elif [[ "$1" == "APPOS" ]]; then
        echo "App+OS pred"
        export LD_PRELOAD=/usr/lib/libos_apppred.so
    elif [[ "$1" == "LIBOS" ]]; then
        echo "Lib+OS pred"
        export LD_PRELOAD=/usr/lib/libos_libpred.so
    elif [[ "$1" == "ONLYINTERCEPT" ]]; then
        echo "Only Intercepting"
        export LD_PRELOAD=/usr/lib/libonlyintercept.so
    elif [[ "$1" == "CACHELIMIT" ]]; then
        echo "OS and LIB pred with Cache Limit"
        export LD_PRELOAD=/usr/lib/libcache_lim_os_libpred.so
    elif [[ "$1" == "FETCHALL" ]]; then
        echo "OS and LIB pred without Cache Limit"
        export LD_PRELOAD=/usr/lib/libos_fetch_at_open.so
    elif [[ "$1" == "FETCHALLSINGLE" ]]; then
        echo "OS and LIB pred without Cache Limit"
        export LD_PRELOAD=/usr/lib/libos_fetch_at_open_single.so
    fi

    ##export TARGET_GPPID=$PPID
}

BUILD_LIB()
{
    cd $SHARED_LIBS/pred
    ./compile.sh
    cd $DBHOME
}

CLEAR_PWD()
{
    cd $DBDIR
    rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
    cd ..
}

#DISABLE_LOCK_STATS

#Run write workload twice
CLEAR_PWD
$DBHOME/db_bench $PARAMS $WRITEARGS
#exit

#LOCKDAT=$PWD/lockdat
#mkdir $LOCKDAT



echo "RUNNING Vanilla................."
FlushDisk
#export APPCACHELIMIT=`echo "10*$GB" | bc`
#SETPRELOAD "CACHELIMIT"
#SETPRELOAD "FETCHALL"
#SETPRELOAD "ONLYOS"
$DBHOME/db_bench $PARAMS $READARGS 
export LD_PRELOAD=""
FlushDisk


exit

echo "RUNNING Only Intercept.................."
FlushDisk
SETPRELOAD "FETCHALLSINGLE"
$DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk
exit

echo "RUNNING APP+OS Pred.................."
FlushDisk
SETPRELOAD "APPOS"
$DBHOME/db_bench $PARAMS $READARGS |& grep "$WORKLOAD"
export LD_PRELOAD=""
FlushDisk

exit

echo "RUNNING NO Pred.................."
FlushDisk
SETPRELOAD "NOPRED"
$DBHOME/db_bench $PARAMS $READARGS |& grep "$WORKLOAD"
export LD_PRELOAD=""
FlushDisk

#/users/shaleen/ssd/ltrace/ltrace -w 5 -rfSC -l /usr/lib/libnopred.so $DBHOME/db_bench $PARAMS $READARGS
