#!/bin/bash
DBHOME=$PWD
THREAD=4
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
NUM=1000000
DBDIR=$DBHOME/DATA


PERF=/users/shaleen/ssd/linux-5.14.0/tools/perf/perf #Path to perf
VMLINUX=/boot/vmlinux-5.14.0-bcc-locks+ # will get this with compiled kernel only
#PERFARGS=" record -e cpu-cycles,instructions --vmlinux=$VMLINUX"
#REPORTARGS=" report --sort=dso -m -k $VMLINUX --demangle --demangle-kernel"
REPORTARGS=" report -k $VMLINUX -g graph"
PRELOAD_LIB=""

#sudo sh -c "echo \"kernel.kptr_restrict=0\" >> /etc/sysctl.conf"
#sudo sh -c "echo \"kernel.perf_event_paranoid=-1\" >> /etc/sysctl.conf"
#sudo sysctl -p /etc/sysctl.conf

sudo sysctl -w kernel.kptr_restrict=0
sudo sysctl -w kernel.perf_event_paranoid=-1


DEV=/dev/nvme1n1p1
BLOCK_SZ=512 #Bytes
RA_SIZE=128 #KB
NR_RA_BLOCKS=`echo "($RA_SIZE*1024)/$BLOCK_SZ" | bc`
sudo blockdev --setra $NR_RA_BLOCKS $DEV

WORKLOAD="readseq"
#WORKLOAD="readrandom"
#WORKLOAD="readreverse"
WRITEARGS="--benchmarks=fillrandom --use_existing_db=0 --threads=1"
READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD"
#READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD --advise_random_on_open=false --readahead_size=2097152 --compaction_readahead_size=2097152 --log_readahead_size=2097152"
APPPREFIX="/usr/bin/time -v"

PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --num=$NUM"


FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
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
        PRELOAD_LIB="/usr/lib/libcrosslayer.so"
    elif [[ "$1" == "NOPRED" ]]; then ##None
        echo "setting nopred"
        PRELOAD_LIB="/usr/lib/libnopred.so"
    elif [[ "$1" == "ONLYAPP" ]]; then
        echo "only app pred"
        PRELOAD_LIB="/usr/lib/libonlyapppred.so"
    elif [[ "$1" == "ONLYLIB" ]]; then
        echo "only Lib pred"
        PRELOAD_LIB="/usr/lib/libonlylibpred.so"
    elif [[ "$1" == "ONLYOS" ]]; then
        echo "only OS pred"
        PRELOAD_LIB="/usr/lib/libonlyospred.so"
    elif [[ "$1" == "APPOS" ]]; then
        echo "App+OS pred"
        PRELOAD_LIB="/usr/lib/libos_apppred.so"
    elif [[ "$1" == "LIBOS" ]]; then
        echo "Lib+OS pred"
        PRELOAD_LIB="/usr/lib/libos_libpred.so"
    fi
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

DISABLE_LOCK_STATS

#Run write workload twice
#CLEAR_PWD
#$DBHOME/db_bench $PARAMS $WRITEARGS

LOCKDAT=$PWD/lockdat
mkdir $LOCKDAT

echo "RUNNING Only App Pred.................."
FlushDisk
SETPRELOAD "ONLYAPP"
PERF_OUT="perf_${WORKLOAD}_ONLYAPP_${THREAD}_ra-${RA_SIZE}KB"
PERFARGS="record -e cpu-cycles,instructions,faults,duration_time -g --call-graph fp --vmlinux=$VMLINUX --output=$PERF_OUT env LD_PRELOAD=$PRELOAD_LIB"
$PERF $PERFARGS $DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk
#$PERF $REPORTARGS -i $PERF_OUT


echo "RUNNING Only OS Pred.................."
FlushDisk
SETPRELOAD "ONLYOS"
PERF_OUT="perf_${WORKLOAD}_ONLYOS_${THREAD}_ra-${RA_SIZE}KB"
PERFARGS="record -e cpu-cycles,instructions,faults,duration_time -g --call-graph fp --vmlinux=$VMLINUX --output=$PERF_OUT env LD_PRELOAD=$PRELOAD_LIB"
$PERF $PERFARGS $DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk

echo "RUNNING APP+OS Pred.................."
FlushDisk
SETPRELOAD "APPOS"
PERF_OUT="perf_${WORKLOAD}_APPOS_${THREAD}_ra-${RA_SIZE}KB"
PERFARGS="record -e cpu-cycles,instructions,faults,duration_time -g --call-graph fp --vmlinux=$VMLINUX --output=$PERF_OUT env LD_PRELOAD=$PRELOAD_LIB"
$PERF $PERFARGS $DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk

echo "RUNNING NO Pred.................."
FlushDisk
SETPRELOAD "NOPRED"
PERF_OUT="perf_${WORKLOAD}_NOPRED_${THREAD}_ra-${RA_SIZE}KB"
PERFARGS="record -e cpu-cycles,instructions,faults,duration_time -g --call-graph fp --vmlinux=$VMLINUX --output=$PERF_OUT env LD_PRELOAD=$PRELOAD_LIB"
$PERF $PERFARGS $DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk

#/users/shaleen/ssd/ltrace/ltrace -w 5 -rfSC -l /usr/lib/libnopred.so $DBHOME/db_bench $PARAMS $READARGS
