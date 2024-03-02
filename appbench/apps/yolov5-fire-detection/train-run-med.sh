#!/bin/bash
#set -x
DBHOME=$PWD
INSTANCES=0
BATCH_SIZE=$1
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
DBDIR=$DBHOME/DATA
#DBDIR=/mnt/remote/DATA


if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi


WORKLOAD="yolov5-fire-detection"
APPPREFIX="/usr/bin/time -v"

APP=python
APPOUTPUTNAME="yolov5-fire-detection"
RESULTS="RESULTS"/$WORKLOAD
RESULTFILE=""

mkdir -p $RESULTS

declare -a workload_arr=("multireadrandom" "readrandom" "readreverse" "readseq" "readwhilescanning")
declare -a membudget=("6" "4" "2" "8")
declare -a membudget=("6")
USEDB=1
MEM_REDUCE_FRAC=0
ENABLE_MEM_SENSITIVE=0

#Enable sensitivity to vary prefetch size and prefetch thread count
ENABLE_SENSITIVITY=1


declare -a membudget=("6")
declare -a trials=("TRIAL1")
declare -a thread_arr=("32")
declare -a config_arr=("Vanilla")


G_TRIAL="TRIAL1"
#Require for large database
ulimit -n 1000000 

workload_arr_in=$1
config_arr_in=$2
thread_arr_in=$3

glob_prefetchsz=1024
glob_prefechthrd=8

declare -a prefech_sz_arr=("1024" "2048" "4096") #"512" "256" "128" "64" 
declare -a prefech_thrd_arr=("1" "8")


FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        #sudo dmesg --clear
        sleep 5
}

CLEAR_DATA()
{
        sudo killall $APP
        sudo killall $APP
        sleep 3
        sudo killall $APP
        rm -rf $DBDIR/*
}



COMPILE_AND_WRITE()
{
	cd $PREDICT_LIB_DIR
	make clean
	$PREDICT_LIB_DIR/compile.sh &> compile.out
	cd $DBHOME
	cd yolov5
	python train.py --img 640 --batch $BATCH_SIZE --epochs 10 --data ../fire_config.yaml --weights yolov5s.pt --workers $INSTANCES
}

COMPILE_AND_WRITE
