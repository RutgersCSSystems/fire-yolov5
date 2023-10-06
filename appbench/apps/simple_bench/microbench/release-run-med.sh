#!/bin/bash
#set -x

if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi

DBHOME=$PWD
WORKLOAD=shared

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

base=$APPS/simple_bench/multi_thread_read

APPOUTPUTNAME="SIMPLEBENCH"

RESULTS="RESULTS"/$WORKLOAD
RESULTFILE=""

declare -a nproc=("1" "2" "4" "8" "16")
declare -a nproc=("16")
declare -a readsize_arr=("16384" "4096" "65536")
#declare -a workload_arr=("seq_private" "rand_private") 
declare -a workload_arr=("rand_private") 
declare -a config_arr=("Vanilla"  "OSonly" "CII" "CIPI")

STATS=0 #0 for perf runs and 1 for stats
NR_STRIDE=4 ##In pages, only relevant for strided
FILESIZE=10000000000 ##GB

echo 0 | sudo tee /proc/sys/kernel/randomize_va_space

G_TRIAL="TRIAL1"

#Require for large database
ulimit -n 1000000
declare -a trials=("TRIAL1")
declare -a membudget=("4")

USEDB=0
MEM_REDUCE_FRAC=0
ENABLE_MEM_SENSITIVE=0

#Compiles the application
COMPILE_APP() {
	make clean
	make -j4
}

#deletes all the Read files
CLEAR_FILES() {
        pushd $base
        rm -rf DATA/*
        popd
}

#takes Workload and filesize
CLEAN_AND_WRITE() {
    printf "in ${FUNCNAME[0]}\n"

    UNSETPRELOAD
    pushd $base

    #echo "IN CLEAN_AND_WRITE $1 $2"

    if [[ "$1" == *"shared"* ]]; then
        echo "Shared File"
        FILENAME="./threads_1/bigfakefile0.txt"
        FILESZ=$(stat -c %s $FILENAME)
        FILESIZE_WANTED=`echo "$2*$GB" | bc`

        #echo "FILESIZE: $FILESZ FILESIZE_WANTED: $FILESIZE_WANTED"

        if [[ -z ${FILESZ} ]];
        then
            FILESZ=0
        fi

        if [ "$FILESZ" -ne "$FILESIZE_WANTED" ]; then
            CLEAR_FILES
            #echo "FILESIZE: $FILESZ FILESIZE_WANTED: $FILESIZE_WANTED"
            $base/bin/write_shared
        fi
    else
        #echo "Pvt Files"
        CLEAR_FILES
        $base/bin/write_pvt
    fi

    popd

    FlushDisk
}

GEN_RESULT_PATH() {
        WORKLOAD=$1
        CONFIG=$2
        THREAD=$3
	READSIZE=$4
        if [ "$STATS" -eq "1" ]; then
                RESULTS=$OUTPUTDIR"-"$G_TRIAL/${APPOUTPUTNAME}_STATS/$WORKLOAD"-READSIZE-"$READSIZE/$THREAD/
        else
                RESULTS=$OUTPUTDIR"-"$G_TRIAL/${APPOUTPUTNAME}/$WORKLOAD"-READSIZE-"$READSIZE/$THREAD/
        fi
        mkdir -p $RESULTS
        RESULTFILE=$RESULTS/$CONFIG.out
}

RUN() {
        #echo "STARTING to RUN"
	cd $PREDICT_LIB_DIR
	$PREDICT_LIB_DIR/compile.sh &> compile.out
	cd $base

        for READSIZE in "${readsize_arr[@]}"
        do
		for NPROC in "${nproc[@]}"
		do
				for WORKLOAD in "${workload_arr[@]}"
				do

					#COMPILE_APP $FILESIZE $READSIZE $NPROC
					#CLEAN_AND_WRITE $WORKLOAD $FILESIZE
					for CONFIG in "${config_arr[@]}"
					do
						#echo "######################################################,"
						GEN_RESULT_PATH $WORKLOAD $CONFIG $NPROC $READSIZE
						`./clearcache.sh`

						export LD_PRELOAD=/usr/lib/lib_$CONFIG.so
						echo "$WORKLOAD.sh $CONFIG"
						cd $DBHOME
						$DBHOME/"$WORKLOAD.sh" $CONFIG $READSIZE #&> $RESULTFILE
						export LD_PRELOAD=""
						REFRESH
					done
				done
			done
		done
}


for G_TRIAL in "${trials[@]}"
do
	RUN
done

rm -rf compile.out
