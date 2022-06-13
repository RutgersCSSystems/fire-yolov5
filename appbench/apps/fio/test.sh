#!/bin/bash

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo dmesg --clear
    sleep 2
}

#declare -a nproc=("1" "2" "4" "8" "16")

TOTSIZE=32 ##GB
NPROC=8

SIZE=`echo "$TOTSIZE/$NPROC" | bc`
NAME=NVME_${NPROC}

#COMMAND="fio --name=$NAME --directory=./fio-test --ioengine=psync --rw=read --bs=4k --numjobs=$NPROC --size=${SIZE}g --iodepth=1 --fadvise_hint=0 #> out_$NAME"
COMMAND="fio --name=$NAME --directory=./fio-test --ioengine=psync --rw=read --bs=512 --numjobs=$NPROC --size=${SIZE}g --iodepth=1 --fadvise_hint=0 --thread"


WRITE() {
        echo "Preparing file if not already there"
        mkdir fio-test
        $COMMAND
}


#WRITE

<< 'vanilla'
echo "Vanilla.................."
FlushDisk
export LD_PRELOAD=""
$COMMAND
export LD_PRELOAD=""
FlushDisk
vanilla

echo "Cross_Naive.................."
FlushDisk
export LD_PRELOAD=/usr/lib/lib_Cross_Naive.so
#export LD_PRELOAD=/usr/lib/lib_INTERCEPT.so
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


<< 'comment'
for NPROC in "${nproc[@]}"
do
        SIZE=`echo "$TOTSIZE/$NPROC" | bc`
        NAME=NVME_${NPROC}

        FlushDisk
        export LD_PRELOAD=/usr/lib/lib_INTERCEPT.so
        #export LD_PRELOAD=/users/shaleen/ssd/prefetching/shared_libs/simple_prefetcher/lib_INTERCEPT.so
        #ltrace -C -f -S -l /users/shaleen/ssd/prefetching/shared_libs/simple_prefetcher/lib_INTERCEPT.so fio --name=$NAME --directory=./fio-test --ioengine=psync --rw=read --bs=4k --numjobs=$NPROC --size=${SIZE}g --iodepth=1 --fadvise_hint=0 #> out_$NAME
        fio --name=$NAME --directory=./fio-test --ioengine=psync --rw=read --bs=4k --numjobs=$NPROC --size=${SIZE}g --iodepth=1 --fadvise_hint=0 #> out_$NAME
        export LD_PRELOAD=""
        exit
done
comment


#fio --name=nvme --directory=./fio-test --time_based --size=10G --direct=0 --verify=0 --bs=4K --iodepth=1024 --rw=read --group_reporting=1 --numjobs=4



#fio can do strided reads 
