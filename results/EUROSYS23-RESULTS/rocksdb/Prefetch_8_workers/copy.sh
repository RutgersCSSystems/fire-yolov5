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
mem_per=1

declare -a workload_arr=("readseq" "readrandom") ##read binaries
declare -a experiment=("VANILLA" "OSONLY" "CBNBB" "CBNMB" "CBPBB" "CBPMB" "CFNMB" "CFPMB")

OUTFILENAME="num-${num}_valuesz-${valuesz}_keysz-${keysz}_mem_per-${mem_per}"
for WORKLOAD in "${workload_arr[@]}"
do
        for EXPERIMENT in "${experiment[@]}"
        do
                OUTFOLDER=$PWD/plots/bandwidth_v_th_memlimit/$WORKLOAD/mem_per-${mem_per}
                CREATE_OUTFOLDER $OUTFOLDER

                cp $PWD/$EXPERIMENT/$WORKLOAD/$OUTFILENAME $OUTFOLDER/${EXPERIMENT}_${WORKLOAD}.csv
        done
done

