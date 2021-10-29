#!/bin/bash

##This script will call variation scripts from different apps

source $RUN_SCRIPTS/generic_funcs.sh

#declare -a apparr=("strided_madbench" "rocksdb" "graphchi" "ior")
declare -a apparr=("strided_madbench")
declare -a nprocarr=("4")

##This is used as results location; change the app scripts according to the experiment you want to run
EXPERIMENT="hitrate" 

#Here is where we run the application
RUNAPP()
{
    APP=$2
    NPROC=$1
    OUTPUT=${OUTPUT_FOLDER}/${APP}/${EXPERIMENT}/NPROC_${NPROC}

    if [ "$APP" = "strided_madbench" ]; then
         $RUN_SCRIPTS/run_strided_madbench.sh $NPROC $EXPERIMENT $OUTPUT
    fi

    if [ "$APP" = "rocksdb" ]; then
        ##call the rocksdb script
    fi
}


for APP in "${apparr[@]}"
do
    for NPROC in "${nprocarr[@]}"
    do	
        REFRESH
        RUNAPP $NPROC $APP 
        REFRESH
    done	
done
