#!/bin/bash
set -x

##This script will call variation scripts from different apps
if [ -z "$APPS" ]; then
    echo "APPS environment variable is undefined."
    echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
    exit 1
fi

source $RUN_SCRIPTS/generic_funcs.sh

#declare -a apparr=("strided_madbench" "rocksdb" "graphchi" "ior")
declare -a apparr=("rocksdb")
#declare -a apparr=("libgrape")
#declare -a apparr=("strided_madbench")
declare -a nprocarr=("8" "4")

##This is used as results location; change the app scripts according to the experiment you want to run
EXPERIMENT="CACHESTAT"

#Here is where we run the application
RUNAPP()
{
    APP=$2
    NPROC=$1
    OUTPUT=${OUTPUT_FOLDER}/${EXPERIMENT}/${APP}/NPROC_${NPROC}
    mkdir -p $OUTPUT

    if [ "$APP" = "strided_madbench" ]; then
         $RUN_SCRIPTS/run_strided_madbench.sh $NPROC $EXPERIMENT $OUTPUT
    elif [ "$APP" = "graphchi" ]; then
	 $RUN_SCRIPTS/run_graphchi.sh $NPROC $EXPERIMENT $OUTPUT	
    elif [ "$APP" = "rocksdb" ]; then
         $RUN_SCRIPTS/run_db_bench.sh $NPROC $EXPERIMENT $OUTPUT
    elif [ "$APP" = "libgrape" ]; then
         $RUN_SCRIPTS/run_libgrape.sh $NPROC $EXPERIMENT $OUTPUT
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
