#!/bin/bash
set +x

##This script will call variation scripts from different apps
if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi

source $RUN_SCRIPTS/generic_funcs.sh

#declare -a apparr=("strided_madbench" "rocksdb" "graphchi" "ior")
declare -a apparr=("simple_bench_shared" "simple_bench_pvt" "rocksdb")
#declare -a apparr=("libgrape")
#declare -a apparr=("strided_madbench")
#experiment names should be same as preloadlib names in SETPRELOAD
#declare -a experiment=("VANILLA" "OSONLY" "CFNMB" "CFPMB" "CBPMB")
declare -a experiment=("VANILLA" "CBNMB" "CFNMB" "CFPMB" "CBPMB")
#declare -a experiment=("CFPMB" "CBPMB")
#C - Cross
#F - FileRA, B - BlockRS
#N - NoPred, P - Pred
#M - MaxMem, B - Budget
#B - BG, F - FG

#Here is where we run the application
RUNAPP()
{
        APP=$1
        EXPERIMENT=$2
        OUTPUT=${OUTPUT_FOLDER}/${APP}/PrefetchPerf_${RIGHTNOW}/${EXPERIMENT}
        mkdir -p $OUTPUT

        if [ "$APP" = "strided_madbench" ]; then
                $RUN_SCRIPTS/run_strided_madbench.sh $EXPERIMENT $OUTPUT
        elif [ "$APP" = "graphchi" ]; then
                $RUN_SCRIPTS/run_graphchi.sh $EXPERIMENT $OUTPUT	
        elif [ "$APP" = "rocksdb" ]; then
                $RUN_SCRIPTS/run_dbbench.sh $EXPERIMENT $OUTPUT
        elif [ "$APP" = "simple_bench_pvt" ]; then
                $RUN_SCRIPTS/run_simple_bench_pvt.sh $EXPERIMENT $OUTPUT
        elif [ "$APP" = "simple_bench_shared" ]; then
                $RUN_SCRIPTS/run_simple_bench_shared.sh $EXPERIMENT $OUTPUT
        elif [ "$APP" = "libgrape" ]; then
                $RUN_SCRIPTS/run_libgrape.sh $EXPERIMENT $OUTPUT
        fi
}


for APP in "${apparr[@]}"
do
        for EXPERIMENT in "${experiment[@]}"
        do
                REFRESH
                RUNAPP $APP $EXPERIMENT
                REFRESH
        done
done	
