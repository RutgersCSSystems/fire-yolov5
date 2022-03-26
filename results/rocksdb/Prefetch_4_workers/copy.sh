#!/bin/bash


#This scripts only copies files from results folder to plots folder
#No other work done here

filesize=40 ##GB
read_size=20 ## in pages

declare -a workload_arr=("readseq" "readrand") ##read binaries
declare -a experiment=("VANILLA" "OSONLY" "CFNMB" "CFPMB" "CBPMB" "CBNBB" "CBNMB" "CBPBB")


#OUTFILENAME="filesz-${filesize}_Readsz-${read_size}"
OUTFILENAME="num-1000000_valuesz-4096_keysz-1000_mem_per-1"

for WORKLOAD in "${workload_arr[@]}"
do
        for EXPERIMENT in "${experiment[@]}"
        do
                cp $PWD/$EXPERIMENT/$WORKLOAD/$OUTFILENAME $PWD/plots/$WORKLOAD/${EXPERIMENT}_${WORKLOAD}.plot
        done
done
