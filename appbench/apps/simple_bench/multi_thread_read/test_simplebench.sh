#!/bin/bash

if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

#WORKLOAD="read_pvt_strided"
WORKLOAD="read_pvt_strided"
COMMAND="./bin/$WORKLOAD"

WRITE_LOAD="write_pvt"

FILESIZE=5 ##in GB
READ_SIZE=32 ## In pages
NR_STRIDE=64 ##in pages
THREADS=1

CLEAR_FILES() {
        rm -rf bigfakefile*
}

#Compiles the application
COMPILE_APP() {
        CREATE_OUTFOLDER ./bin
        echo $NR_STRIDE
        make -j SIZE=$1 NR_READ_PAGES=$2 NR_THREADS=$3 NR_STRIDE=$4
}


CLEAN_AND_WRITE() {
        printf "in ${FUNCNAME[0]}\n"

        UNSETPRELOAD
        CLEAR_FILES

        ./bin/${WRITE_LOAD}

        FlushDisk
}

COMPILE_APP $FILESIZE $READ_SIZE $THREADS $NR_STRIDE
#CLEAN_AND_WRITE
FlushDisk

echo "Vanilla"
$COMMAND
FlushDisk

echo "#########################"
#SETPRELOAD "CNI"
#$COMMAND
#export LD_PRELOAD=""
#free -h
#FlushDisk

echo "#########################"
SETPRELOAD "CPNI"
$COMMAND
export LD_PRELOAD=""
free -h
FlushDisk
