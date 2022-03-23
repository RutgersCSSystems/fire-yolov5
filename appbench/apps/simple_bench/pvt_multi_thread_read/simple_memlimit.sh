#!/bin/bash

if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

umount_ext4ramdisk

#WORKLOAD="read_seq"
WORKLOAD="read_pvt_seq"
WRITE_LOAD="write_pvt"

experiment=$1 #which preload library to call

FILESIZE=40 ##in GB
READ_SIZE=20 ## In pages
THREAD=16
NR_STRIDE=64

#declare -a filesize=("40")

#deletes all the Read files
CLEAR_FILES() {
        rm -rf bigfakefile*
}

#Compiles the application
COMPILE_APP() {
        CREATE_OUTFOLDER ./bin
        make -j SIZE=$1 NR_READ_PAGES=$2 NR_THREADS=$3 NR_STRIDE=$4
}


CLEAN_AND_WRITE() {
        printf "in ${FUNCNAME[0]}\n"

        UNSETPRELOAD
        CLEAR_FILES

        ./bin/${WRITE_LOAD}

        FlushDisk
}



COMPILE_APP $FILESIZE $READ_SIZE $THREAD $NR_STRIDE
CLEAN_AND_WRITE
FlushDisk

COMMAND="./bin/$WORKLOAD"

printf "\nRUNNING Memlimit.................\n"
SETPRELOAD "VANILLA"
#export LD_PRELOAD=/usr/lib/lib_memusage.so
$COMMAND
export LD_PRELOAD=""
FlushDisk

anon=100
cache=40960

free -h

SETUPEXTRAM_1 `echo "scale=0; ($anon + ($cache * 0.2))/1" | bc --mathlib`

free -h

printf "\nRUNNING VANILLA.................\n"
SETPRELOAD "VANILLA"
$COMMAND
export LD_PRELOAD=""
FlushDisk

printf "\nRUNNING CROSS_BLOCKRA_NOPRED_MAXMEM_BG................\n"
SETPRELOAD "CBNMB"
$COMMAND
export LD_PRELOAD=""
FlushDisk

printf "\nRUNNING CROSS_BLOCKRA_NOPRED_BUDGET_BG................\n"
SETPRELOAD "CBNBB"
$COMMAND
export LD_PRELOAD=""
FlushDisk

umount_ext4ramdisk
exit

printf "\nRUNNING CROSS_BLOCKRA_PRED_MAXMEM_BG................\n"
SETPRELOAD "CBPMB"
$COMMAND
export LD_PRELOAD=""
FlushDisk


printf "\nRUNNING CROSS_FILERA_PRED_MAXMEM_BG................\n"
SETPRELOAD "CFPMB"
$COMMAND
export LD_PRELOAD=""
FlushDisk
