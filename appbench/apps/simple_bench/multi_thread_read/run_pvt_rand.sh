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
        sudo sh -c "echo 0 > /proc/lock_stat"
        sudo sh -c "echo 1 > /proc/sys/kernel/lock_stat"
}

DISABLE_LOCK_STATS()
{
        sudo sh -c "echo 0 > /proc/sys/kernel/lock_stat"
}

NR_STRIDE=64 ##In pages, only relevant for strided
FILESIZE=50 ##GB

NR_RA_PAGES=2560L #nr_pages
NR_READ_PAGES=512

##These need to be equivalent of the above
RA_SIZE=10M ##MB
READ_SIZE=2M ##MB

APP="./bin/read_pvt_rand"

declare -a nproc=("16" "4" "8" "1" "32")

#deletes all the Read files
CLEAR_FILES() {
        rm -rf ./threads_*/
}

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
        echo "Read Shared Seq Vanilla RA"
        FlushDisk
        ENABLE_LOCK_STATS
        export LD_PRELOAD="/usr/lib/lib_Vanilla.so"
        #./bin/read_shared_seq_vanilla
	${APP}_vanilla
        export LD_PRELOAD=""
        DISABLE_LOCK_STATS
        sudo dmesg -c
        sudo cat /proc/lock_stat
}

VanillaOPT() {
        echo "Read Shared Seq Vanilla RA OPT"
        FlushDisk
        ENABLE_LOCK_STATS
        export LD_PRELOAD="/usr/lib/lib_Vanilla.so"
	${APP}_vanilla_opt
        #./bin/read_shared_seq_vanilla_opt
        export LD_PRELOAD=""
        DISABLE_LOCK_STATS
        sudo dmesg -c
        sudo cat /proc/lock_stat
}

OSonly() {
        echo "OS Only"
        FlushDisk
        ENABLE_LOCK_STATS
        export LD_PRELOAD="/usr/lib/lib_OSonly.so"
        #./bin/read_shared_seq
	${APP}
        export LD_PRELOAD=""
        DISABLE_LOCK_STATS
        sudo dmesg -c
        sudo cat /proc/lock_stat
}

CrossInfo() {
        echo "Cross Info"
        FlushDisk
        ENABLE_LOCK_STATS
        export LD_PRELOAD="/usr/lib/lib_Cross_Info.so"
	${APP}
        export LD_PRELOAD=""
        DISABLE_LOCK_STATS
        sudo dmesg -c
        sudo cat /proc/lock_stat
}

CII() {
        echo "Cross Info IOOPT"
        FlushDisk
        ENABLE_LOCK_STATS
        export LD_PRELOAD="/usr/lib/lib_CII.so"
	${APP}
        export LD_PRELOAD=""
        DISABLE_LOCK_STATS
        sudo dmesg -c
        sudo cat /proc/lock_stat
}

CIP() {
        echo "Cross Info IOOPT"
        FlushDisk
        ENABLE_LOCK_STATS
        export LD_PRELOAD="/usr/lib/lib_CIP.so"
	${APP}
        export LD_PRELOAD=""
        DISABLE_LOCK_STATS
        sudo dmesg -c
        sudo cat /proc/lock_stat
}

MINCORE() {
        echo "Mincore"
        FlushDisk
        ENABLE_LOCK_STATS
        export LD_PRELOAD=""
        #./bin/read_shared_seq_mincore
        ${APP}_mincore
        export LD_PRELOAD=""
        DISABLE_LOCK_STATS
        sudo dmesg -c
        sudo cat /proc/lock_stat
}


for NPROC in "${nproc[@]}"
do
        COMPILE_APP $NPROC
        #CLEAN_AND_WRITE

        FILENAMEBASE="stats_pvt_rand_${READ_SIZE}r_${RA_SIZE}pgra_$NPROC"

        VanillaRA &> VanillaRA_${FILENAMEBASE}
        #VanillaOPT &> VanillaOPT_${FILENAMEBASE}
        OSonly &> OSonly_${FILENAMEBASE}
        CrossInfo &> CrossInfo_${FILENAMEBASE}
        CII &> CII_${FILENAMEBASE}
        CIP &> CIP_${FILENAMEBASE}
        MINCORE &> MINCORE_${FILENAMEBASE}
done

