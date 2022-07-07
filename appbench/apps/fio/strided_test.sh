#!/bin/bash

FlushDisk()
{
    sudo sh -c "echo 1 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 1 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    #sudo dmesg --clear
    sleep 2
}

#declare -a nproc=("1" "2" "4" "8" "16")

TOTSIZE=16 ##GB
NPROC=2
SKIP=10 #Nr pages for strided access

SIZE=`echo "$TOTSIZE/$NPROC" | bc`
NAME=NVME_${NPROC}

SKIP_KB=`echo "$SKIP*4" | bc`

#COMMAND="fio --name=$NAME --directory=./fio-test --ioengine=psync --rw=read --bs=4k --numjobs=$NPROC --size=${SIZE}g --iodepth=1 --fadvise_hint=0 #> out_$NAME"
#COMMAND="fio --name=$NAME --directory=./fio-test --ioengine=psync --rw=read --bs=4k --numjobs=$NPROC --size=${SIZE}g --iodepth=1 --fadvise_hint=0 --thread --thinktime=1"
COMMAND="fio --name=$NAME --directory=./fio-test --ioengine=psync --rw=read:${SKIP_KB}ki --bs=4ki --numjobs=$NPROC --filesize=${SIZE}gi --iodepth=1 --fadvise_hint=0 --thread"

echo "$COMMAND"


WRITE() {
        echo "Preparing file if not already there"
        mkdir fio-test
        $COMMAND
}


#WRITE

#<< 'vanilla'
echo "Vanilla.................."
FlushDisk
free -h
export LD_PRELOAD=""
#strace -f $COMMAND
#$COMMAND | grep "READ"
$COMMAND
export LD_PRELOAD=""
FlushDisk
#vanilla

free -h


echo "################################################################################"

#echo "Vanilla RA.................."
echo "Cross_Naive.................."
FlushDisk
#export LD_PRELOAD=/usr/lib/lib_Cross_Naive.so
export LD_PRELOAD=/usr/lib/lib_CNI.so
#export LD_PRELOAD=/usr/lib/lib_CPNI.so
#export LD_PRELOAD=/usr/lib/lib_VRAI.so
#ltrace -C -f -S -l /usr/lib/lib_Cross_Naive.so $COMMAND 2> ltrace_out_$TOTSIZE
$COMMAND
export LD_PRELOAD=""
FlushDisk

exit

echo "Cross_Naive_IOOPT.................."
FlushDisk
export LD_PRELOAD=/usr/lib/lib_CNI.so
$COMMAND
export LD_PRELOAD=""
FlushDisk

exit


#fio can do strided reads 
#fio can 
