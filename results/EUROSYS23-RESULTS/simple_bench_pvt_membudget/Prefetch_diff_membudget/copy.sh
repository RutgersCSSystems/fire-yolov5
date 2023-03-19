#!/bin/bash


#This scripts only copies files from results folder to plots folder
#No other work done here

filesize=40 ##GB
read_size=20 ## in pages
nproc=16

#Checks if the folder exits, if not, create new
CREATE_OUTFOLDER() {
        if [[ ! -e $1 ]]; then
                mkdir -p $1
        else
                echo "$1 already exists"
        fi
}

declare -a workload_arr=("read_pvt_rand" "read_pvt_seq") ##read binaries
declare -a experiment=("OSONLY" "CFNMB" "CFPMB" "CBPMB" "CBPBB" "CBNMB" "CBNBB")


OUTFILENAME="filesz-${filesize}_Readsz-${read_size}_nproc-${nproc}"
for WORKLOAD in "${workload_arr[@]}"
do
        for EXPERIMENT in "${experiment[@]}"
        do
                OUTFOLDER=$PWD/plots/bandwidth_v_memlimit/$WORKLOAD
                CREATE_OUTFOLDER $OUTFOLDER

                cp $PWD/$EXPERIMENT/$WORKLOAD/$OUTFILENAME $OUTFOLDER/${EXPERIMENT}_${WORKLOAD}.csv
        done
done
