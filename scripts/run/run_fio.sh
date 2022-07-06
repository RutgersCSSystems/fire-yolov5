#!/bin/bash
set +x

if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

experiment=$1 #which preload library to call
out_base=$2 #base output folder

base=$APPS/fio

DATA_FOLDER=$base/fio-test

declare -a nproc=("1" "2" "4" "8" "16")
declare -a filesize=("32") ##GB
declare -a read_size=("10") ## in pages
declare -a workload_arr=("read_pvt_seq") ##To change this with other fio workloads

#COMMAND="--name=$NAME --bs=4k --numjobs=$NPROC --size=${SIZE}g"
#Base commands
ORI_PARAMS="--directory=$DATA_FOLDER --ioengine=psync --rw=read --iodepth=1 --fadvise_hint=0 --thread"

#deletes all the Read files
CLEAR_FILES() {
        rm -rf $DATA_FOLDER/*
}


CLEAN_AND_WRITE() {
        printf "in ${FUNCNAME[0]}\n"

        CREATE_OUTFOLDER $DATA_FOLDER
        UNSETPRELOAD
        CLEAR_FILES

        WRITE_PARAMS="--name=NVME_${NPROC} --bs=4Ki --numjobs=$NPROC --size=${SIZE}Gi"

        fio $ORI_PARAMS $WRITE_PARAMS

        FlushDisk
}


#Checks if the OUTFILE exists, 
TOUCH_OUTFILE(){
        if [[ ! -e $1 ]]; then
                touch $1
                echo "AppThreads,${experiment}-min,${experiment}-avg,${experiment}-max" > $1
        else
                echo "$1 Exists!"
        fi
}


RUNAPP() {
        COMMAND="fio $ORI_PARAMS $READARGS"
        echo "Running: $COMMAND"
        min_bw=100000000
        max_bw=0
        avg_bw=0
        this_bw=0

        for a in $(seq 1 $NR_REPEATS)
        do
                SETPRELOAD $experiment ##set preload lib based on experiment
                $COMMAND &> tmp
                UNSETPRELOAD
                #########################
                #update raw data for reference
                echo $COMMAND >> ${OUTFILE}_raw
                cat tmp >> ${OUTFILE}_raw
                #########################
                this_bw=`cat tmp | grep "READ" | awk '{print $2}' | grep -o '[0-9]\+'`
                echo "this bandwidth = "$this_bw
                ##########################
                min_bw=$(min_number $this_bw $min_bw)
                max_bw=$(max_number $this_bw $max_bw)
                avg_bw=`echo "scale=2; $avg_bw + $this_bw" | bc -l`
                ##########################
                REFRESH
        done
        avg_bw=`echo "scale=2; $avg_bw/$NR_REPEATS" | bc -l`
        printf "$NPROC,$min_bw,$avg_bw,$max_bw\n" >> ${OUTFILE}
}


for NPROC in "${nproc[@]}"
do
        for FILESIZE in "${filesize[@]}"
        do
                SIZE=`echo "$FILESIZE/$NPROC" | bc`
                CLEAN_AND_WRITE
                for READ_SIZE in "${read_size[@]}"
                do
                        read_kib=`echo "$READ_SIZE*$PAGE_SZ" | bc`
                        READARGS="--name=NVME_${NPROC} --bs=${read_kib}Ki --numjobs=$NPROC --size=${SIZE}Gi"
                        for WORKLOAD in "${workload_arr[@]}"
                        do
                                echo "######################################################,"
                                echo "Filesize=$FILESIZE, load=$WORKLOAD, Experiment=$experiment NPROC=$NPROC Readsz=$READ_SIZE"
                                OUTFOLDER=$out_base/$WORKLOAD
                                CREATE_OUTFOLDER $OUTFOLDER
                                OUTFILENAME="filesz-${FILESIZE}_Readsz-${READ_SIZE}"
                                OUTFILE=$OUTFOLDER/$OUTFILENAME
                                TOUCH_OUTFILE $OUTFILE

                                REFRESH
                                RUNAPP 
                        done
                done
        done
done
