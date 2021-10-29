#!/bin/bash

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

nproc=$1 #nr of mpi procs
experiment=$2 #experiment type
out_folder=$3 #output folder

base=$APPS/strided_MADbench


##TODO:check if the app is already compiled
COMPILE_APP() {

    pushd $base
    ./compile.sh
    popd
}

RUNAPP()
{

    if [ "$experiment" = "hitrate" ]; then
        ##Do hitrate stuff here
    fi
}




COMPILE_APP ##Do this if its not already compiled

