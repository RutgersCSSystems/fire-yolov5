#!/bin/bash


#This scripts only copies files from results folder to plots folder
#No other work done here

filesize=32 ##In GB
mem_per=1 #in num pages

#filesz-32_Readsz-1
#read_pvt_seq

#Checks if the folder exits, if not, create new
CREATE_OUTFOLDER() {
        if [[ ! -e $1 ]]; then
                mkdir -p $1
        else
                echo "$1 already exists"
        fi
}

declare -a workload_arr=("read_pvt_seq") ##read binaries
declare -a experiment=("VANILLA" "OSONLY" "CN" "CNI" "CPNV" "CPNI")


OUTFILENAME="filesz-${filesize}_Readsz-${mem_per}"
for WORKLOAD in "${workload_arr[@]}"
do
        for EXPERIMENT in "${experiment[@]}"
        do
                OUTFOLDER=$PWD/plots/bandwidth_v_threads/$WORKLOAD
                CREATE_OUTFOLDER $OUTFOLDER

                cp $PWD/$EXPERIMENT/$WORKLOAD/$OUTFILENAME $OUTFOLDER/${EXPERIMENT}_${WORKLOAD}.csv
        done
done

