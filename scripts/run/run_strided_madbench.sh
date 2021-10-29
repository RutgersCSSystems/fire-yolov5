#!/bin/bash

if [ -z "$APPS" ]; then
    echo "APPS environment variable is undefined."
    echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
    exit 1
fi

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

nproc=$1 #nr of mpi procs
experiment=$2 #experiment type
out_base=$3 #base output folder

if [[ ! -e $out_base ]]; then
    mkdir -p $out_base
else
    echo "$out_base already exists"
fi

RIGHTNOW=`date +"%H-%M_%m-%d-%y"`
DATE=`date +'%d-%B-%y'`

base=$APPS/strided_MADbench

declare -a workarr=("16384") # size of workload (good to keep a power of 2)
declare -a readsize=("4096") # application read size in bytes (good to keep a power of 2)
# keep stride = (power of 2) - 1 for correct calculation in madbench
declare -a stride=("1" "3" "7" "15") #jump between two reads = $STRIDE * $READSIZE

FLUSH=1 ##FLUSHES and clears cache AFTER EACH WRITE
no_bin=5 ##5,30 Increases the runtime (TODO check why)

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
    COMMAND="$APPPREFIX mpiexec.mpich -n $nproc $base/MADbench2_io $workload $no_bin 1 8 64 1 1 $readsize $stride $FLUSH"

    outfile="all.out"

    if [ "$experiment" = "hitrate" ]; then
        sudo dmesg -c 
        echo "Workload=$workload, readsize=$readsize, stride=$stride, flust=$FLUSH" >> $out_base/$outfile
        SETPRELOAD "JUSTSTATS"
        $COMMAND &>> $out_base/$outfile
        UNSETPRELOAD
        dmesg >> $out_base/$outfile
        echo "\n ################################### \n" >> $out_base/$outfile
    fi
}


COMPILE_APP ##Do this if its not already compiled

for WORKLOAD in "${workarr[@]}"
do
    for READSIZE in "${readsize[@]}"
    do
        for STRIDE in "${stride[@]}"
        do
            REFRESH
            RUNAPP $WORKLOAD $READSIZE $STRIDE
        done
    done
done
