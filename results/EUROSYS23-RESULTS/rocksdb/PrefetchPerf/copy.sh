#!/bin/bash


#This scripts only copies files from results folder to plots folder
#No other work done here

filesize=40 ##GB
read_size=20 ## in pages

declare -a workload_arr=("readseq" "readrand") ##read binaries
declare -a experiment=("VANILLA" "OSONLY" "CFNMB" "CFPMB" "CBPMB")


OUTFILENAME="filesz-${filesize}_Readsz-${read_size}"
for WORKLOAD in "${workload_arr[@]}"
do
        for EXPERIMENT in "${experiment[@]}"
        do
                cp $PWD/$EXPERIMENT/$WORKLOAD/$OUTFILENAME $PWD/plots/$WORKLOAD/${EXPERIMENT}_${WORKLOAD}.plot
        done
done
