#!/bin/bash


#This scripts only copies files from results folder to plots folder
#No other work done here

#Checks if the folder exits, if not, create new
CREATE_OUTFOLDER() {
        if [[ ! -e $1 ]]; then
                mkdir -p $1
        else
                echo "$1 already exists"
        fi
}

num=1000000
valuesz=4096
keysz=1000
nproc=16

declare -a workload_arr=("readseq" "readrandom") ##read binaries
declare -a experiment=("VANILLA" "OSONLY" "CN" "CPBI" "CPBV" "CPNV" "CPNI")

OUTFILENAME="num-${num}_valuesz-${valuesz}_keysz-${keysz}_nproc-${nproc}"
for WORKLOAD in "${workload_arr[@]}"
do
        for EXPERIMENT in "${experiment[@]}"
        do
                OUTFOLDER=$PWD/plots/bandwidth_v_memlimit/$WORKLOAD
                CREATE_OUTFOLDER $OUTFOLDER

                cp $PWD/$EXPERIMENT/$WORKLOAD/$OUTFILENAME $OUTFOLDER/${EXPERIMENT}_${WORKLOAD}.csv
        done
done
