#!/bin/bash

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

nproc=$1 #nr of mpi procs
experiment=$2 #experiment type
out_base=$3 #base output folder

RIGHTNOW=`date +"%H-%M_%m-%d-%y"`
DATE=`date +'%d-%B-%y'`

base=$APPS/strided_MADbench

declare -a workarr=("16384") # size of workload
declare -a readsize=("4096") # application read size in bytes
declare -a stride=("7") #jump between two reads = $STRIDE * $READSIZE
FLUSH=1 ##FLUSHES and clears cache AFTER EACH WRITE

## env variables used by madbench to choose internals
export IOMODE=SYNC
export FILETYPE=UNIQUE
export IOMETHOD=POSIX




##TODO:check if the app is already compiled
COMPILE_APP() {

    pushd $base
    ./compile.sh
    popd
}

RUNAPP()
{
    workload=$1
    readsize=$2
    stride=$3
    COMMAND="$APPPREFIX mpiexec.mpich -n $NPROC $base/MADbench2_io $workload 30 1 8 64 1 1 $readsize $stride $FLUSH"
    if [ "$experiment" = "hitrate" ]; then
        SETPRELOAD "JUSTSTATS"

    fi
}


COMPILE_APP ##Do this if its not already compiled

for WORKLOAD in "${workarr[@]}"
do
    for READSIZE in "${readsize[@]}"
    do
        for STRIDE in "${stride[@]}"
        do
            RUNAPP $WORKLOAD $READSIZE $STRIDE
            REFRESH
        done
    done
done
