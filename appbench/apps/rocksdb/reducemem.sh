#!/bin/bash
#set -x
DBHOME=$PWD
THREAD=16
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
DBDIR=$DBHOME/DATA
#DBDIR=/mnt/remote/DATA


BATCHSIZE=128
YOVLOV_RESULTFILE=""


if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi


#WORKLOAD="readseq"
#WORKLOAD="readreverse"
WORKLOAD="readrandom"
WRITEARGS="--benchmarks=fillseq --use_existing_db=0 --threads=1"
READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD"
#APPPREFIX="/usr/bin/time -v"
APPPREFIX="nice -n -20"

APP=db_bench
APPOUTPUTNAME="ROCKSDB"

RESULTS="RESULTS"/$WORKLOAD
RESULTFILE=""

mkdir -p $RESULTS


#declare -a config_arr=("Vanilla" "Cross_Naive" "CPBI" "CNI" "CPBV" "CPNV" "CPNI")
declare -a num_arr=("20000000")
NUM=20000000

#declare -a thread_arr=("32" "16"  "8"  "4" "1")
#declare -a membudget=("6" "4" "2" "8")
#echo "CAUTION, CAUTION, USE EXITING DB is set to 0 for write workload testing!!!"
#declare -a trials=("TRIAL1" "TRIAL2" "TRIAL3")
USEDB=1
MEM_REDUCE_FRAC=1
ENABLE_MEM_SENSITIVE=1

declare -a membudget=("3")
declare -a trials=("TRIAL1")
declare -a workload_arr=("multireadrandom" "readseq" "readwhilescanning" "readreverse")
declare -a thread_arr=("32")

declare -a config_arr=("Vanilla" "OSonly" "CII" "CIPI_PERF" "CPBI_PERF")


#declare -a config_arr=("CIPI_PERF"  "CPBI_PERF")
declare -a batch_arr=("512" "256" "128" "1024")
declare -a batch_arr=("768" "512" "256" "128")
declare -a config_arr=("CIPI_PERF" "Vanilla" "isolated")

declare -a batch_arr=("60" "80" "100" "20" "40")
declare -a config_arr=("OSonly" "isolated")
declare -a config_arr=("OSonly-prio")


declare -a workload_arr=("multireadrandom")


G_TRIAL="TRIAL1"
#Require for large database
ulimit -n 1000000 

workload_arr_in=$1
config_arr_in=$2
thread_arr_in=$3


GETMEMORYBUDGET() {
        sudo rm -rf  /mnt/ext4ramdisk/*
        $SCRIPTS/mount/umount_ext4ramdisk.sh
        sudo rm -rf  /mnt/ext4ramdisk/*
        sudo rm -rf  /mnt/ext4ramdisk/

        echo "***NODE 0: "$DISKSZ0"****NODE 1: "$DISKSZ1
        $SCRIPTS/mount/releasemem.sh "NODE0"
        $SCRIPTS/mount/releasemem.sh "NODE1"

        let NUMAFREE0=`numactl --hardware | grep "node 0 free:" | awk '{print $4}'`
        let NUMAFREE1=`numactl --hardware | grep "node 1 free:" | awk '{print $4}'`

        echo "MEMORY $1"
        let FRACTION=$1
        let NUMANODE0=$(($NUMAFREE0/$FRACTION))
        let NUMANODE1=$(($NUMAFREE1/$FRACTION))
        let NUMANODE1=500

        let DISKSZ0=$(($NUMAFREE0-$NUMANODE0))
        let DISKSZ1=$(($NUMAFREE1-$NUMANODE1))

        numactl --membind=0 $SCRIPTS/mount/reducemem.sh $DISKSZ0 "NODE0"
        numactl --membind=1 $SCRIPTS/mount/reducemem.sh $DISKSZ1 "NODE1"
}



for G_TRIAL in "${trials[@]}"
do
	if [ "$ENABLE_MEM_SENSITIVE" -eq "1" ]
	then
		for MEM_REDUCE_FRAC in "${membudget[@]}"
		do
			GETMEMORYBUDGET $MEM_REDUCE_FRAC
			exit
			RUN
			$SCRIPTS/mount/releasemem.sh "NODE0"
			$SCRIPTS/mount/releasemem.sh "NODE1"
		done
	else
		RUN
	fi
done


