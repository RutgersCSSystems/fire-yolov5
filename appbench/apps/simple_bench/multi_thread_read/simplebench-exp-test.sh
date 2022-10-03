#!/bin/bash
#set -x

if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

base=$APPS/simple_bench/multi_thread_read

APPOUTPUTNAME="SIMPLEBENCH"

RESULTS="RESULTS"/$WORKLOAD
RESULTFILE=""

declare -a nproc=("1" "2" "4" "8" "16")
declare -a read_size=("20") ## in pages
declare -a workload_arr=("read_shared_seq") ##read binaries
declare -a config_arr=("Vanilla" "VRA" "Cross_Info" "CII")


declare -a nproc=("32")
declare -a read_size=("20") ## in pages
declare -a workload_arr=("read_shared_seq_global_simple") ##read binaries
declare -a config_arr=("Vanilla" "Cross_Info" "CII" "CIP" "CIPI" "OSonly")
#declare -a config_arr=("CIPI" "CIP" )

STATS=1 #0 for perf runs and 1 for stats
NR_STRIDE=64 ##In pages, only relevant for strided
FILESIZE=80 ##GB

echo 0 | sudo tee /proc/sys/kernel/randomize_va_space

#Compiles the application
COMPILE_APP() {
        pushd $base
        CREATE_OUTFOLDER $base/bin
        make -j SIZE=$1 NR_READ_PAGES=$2 NR_THREADS=$3 NR_STRIDE=$NR_STRIDE
        popd
}

#deletes all the Read files
CLEAR_FILES() {
        pushd $base
        rm -rf ./threads_*/
        popd
}

#takes Workload and filesize
CLEAN_AND_WRITE() {
        printf "in ${FUNCNAME[0]}\n"

        UNSETPRELOAD
        pushd $base

	echo "IN CLEAN_AND_WRITE $1 $2"

        if [[ "$1" == *"shared"* ]]; then
                echo "Shared File"
                FILENAME="./threads_1/bigfakefile0.txt"
                FILESZ=$(stat -c %s $FILENAME)
                FILESIZE_WANTED=`echo "$2*$GB" | bc`

		echo "FILESIZE: $FILESZ FILESIZE_WANTED: $FILESIZE_WANTED"

		if [[ -z ${FILESZ} ]];
		then
			FILESZ=0
		fi

                if [ "$FILESZ" -ne "$FILESIZE_WANTED" ]; then
                        CLEAR_FILES
			echo "FILESIZE: $FILESZ FILESIZE_WANTED: $FILESIZE_WANTED"
                        $base/bin/write_shared
                fi
        else
                echo "Pvt Files"
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
        if [ "$STATS" -eq "1" ]; then
                RESULTS=$OUTPUTDIR/${APPOUTPUTNAME}_STATS/$WORKLOAD/$THREAD
        else
                RESULTS=$OUTPUTDIR/${APPOUTPUTNAME}_PERF/$WORKLOAD/$THREAD
        fi
        mkdir -p $RESULTS
        RESULTFILE=$RESULTS/$CONFIG.out
}


RUN() {
        echo "STARTING to RUN"


        for WORKLOAD in "${workload_arr[@]}"
        do
                for NPROC in "${nproc[@]}"
                do
			sed -i "/NR_THREADS_VAR=/c\NR_THREADS_VAR=$NPROC" compile.sh
			./compile.sh

                        for READ_SIZE in "${read_size[@]}"
                        do
                                #COMPILE_APP $FILESIZE $READ_SIZE $NPROC
                                CLEAN_AND_WRITE $WORKLOAD $FILESIZE

                                for CONFIG in "${config_arr[@]}"
                                do
                                        echo "######################################################,"
                                        echo "Filesize=$FILESIZE, load=$WORKLOAD, Experiment=$experiment NPROC=$NPROC Readsz=$READ_SIZE"

                                        GEN_RESULT_PATH $WORKLOAD $CONFIG $NPROC

                                        #if [ "$STATS" -eq "1" ]; then
                                         #       ENABLE_LOCK_STATS
                                        #fi

					`./clearcache.sh`

					echo $RESULTFILE
                                        export LD_PRELOAD=/usr/lib/lib_$CONFIG.so
					$base/bin/$WORKLOAD &> $RESULTFILE
					export LD_PRELOAD=""

                                        #if [ "$STATS" -eq "1" ]; then
                                        #        DISABLE_LOCK_STATS
                                        #fi

					#sudo dmesg -c &>> $RESULTFILE
                                        #sudo cat /proc/lock_stat &>> $RESULTFILE

                                        REFRESH
                                done
                        done
                done
        done
}

RUN
