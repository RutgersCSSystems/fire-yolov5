#!/bin/bash

if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sleep 5
        sudo dmesg --clear
}

ENABLE_LOCK_STATS()
{
        return
        sudo sh -c "echo 0 > /proc/lock_stat"
        sudo sh -c "echo 1 > /proc/sys/kernel/lock_stat"
}

DISABLE_LOCK_STATS()
{
        return
        sudo sh -c "echo 0 > /proc/sys/kernel/lock_stat"
}

NR_STRIDE=64 ##In pages, only relevant for strided
FILESIZE=100 ##GB
NR_RA_PAGES=2560L #nr_pages
NR_READ_PAGES=512

declare -a nproc=("1" "4" "8" "16")

echo "Filesize=$FILESIZE, load=$WORKLOAD, Experiment=$experiment NPROC=$NPROC Readsz=$READ_SIZE"

#Compiles the application
COMPILE_APP() {
        CREATE_OUTFOLDER ./bin
        make -j SIZE=$FILESIZE NR_READ_PAGES=$NR_READ_PAGES NR_THREADS=$1 NR_STRIDE=$NR_STRIDE NR_RA_PAGES=$NR_RA_PAGES
}


#takes Workload and filesize
CLEAN_AND_WRITE() {
        printf "in ${FUNCNAME[0]}\n"

        UNSETPRELOAD

        CLEAR_FILES
        ./bin/write_pvt

        FlushDisk
}

VanillaRA() {
        echo "Read Pvt Seq Vanilla RA"
        FlushDisk
        ENABLE_LOCK_STATS
        export LD_PRELOAD="/usr/lib/lib_Vanilla.so"
        ./bin/read_pvt_seq_vanilla
        export LD_PRELOAD=""
        DISABLE_LOCK_STATS
        #dmesg
        #sudo cat /proc/lock_stat
}

VanillaOPT() {
        echo "Read Pvt Seq Vanilla RA OPT"
        FlushDisk
        ENABLE_LOCK_STATS
        export LD_PRELOAD="/usr/lib/lib_Vanilla.so"
        ./bin/read_pvt_seq_vanilla_opt
        export LD_PRELOAD=""
        DISABLE_LOCK_STATS
        #dmesg
        #sudo cat /proc/lock_stat
}

OSonly() {
        echo "OS Only"
        FlushDisk
        ENABLE_LOCK_STATS
        export LD_PRELOAD="/usr/lib/lib_OSonly.so"
        ./bin/read_pvt_seq_vanilla_opt
        export LD_PRELOAD=""
        DISABLE_LOCK_STATS
        #dmesg
        #sudo cat /proc/lock_stat
}

CrossInfo() {
        echo "Cross Info"
        FlushDisk
        ENABLE_LOCK_STATS
        export LD_PRELOAD="/usr/lib/lib_Cross_Info.so"
        ./bin/read_pvt_seq
        export LD_PRELOAD=""
        DISABLE_LOCK_STATS
        #dmesg
        #sudo cat /proc/lock_stat
}

CII() {
        echo "Cross Info IOOPT"
        FlushDisk
        ENABLE_LOCK_STATS
        export LD_PRELOAD="/usr/lib/lib_CII.so"
        ./bin/read_pvt_seq
        export LD_PRELOAD=""
        DISABLE_LOCK_STATS
        #dmesg
        #sudo cat /proc/lock_stat
}


for NPROC in "${nproc[@]}"
do
        COMPILE_APP $NPROC
        VanillaRA &> VanillaRA_perf_pvt_seq_2Mr_10Mra_$NPROC
        VanillaOPT &> VanillaOPT_perf_pvt_seq_2Mr_10Mra_$NPROC
        OSonly &> OSonly_perf_pvt_seq_2Mr_10Mra_$NPROC
        CrossInfo &> CrossInfo_perf_pvt_seq_2Mr_10Mra_$NPROC
        CII &> CII_perf_pvt_seq_2Mr_10Mra_$NPROC
done
