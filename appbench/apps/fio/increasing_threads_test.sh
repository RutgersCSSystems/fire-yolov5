#!/bin/bash

##Tests fio read performance with increasing number of threads

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sleep 5
}

FILESIZE=40G

declare -a nr_threads=("1" "2" "4" "8" "16")
declare -a IOENGINES=("sync" "psync" "libaio" "posixaio")

NR_THREADS=1

FIOTEST()
{
        IOENGINE=$1
        rm ./fio-test/*
        for NR_THREADS in "${nr_threads[@]}"
        do
                echo "######################################"
                echo "$NR_THREADS threads, $FILESIZE GB file, $IOENGINE"

                fio --name=nvme --directory=./fio-test --filename=test.txt --size=$FILESIZE --ioengine=$IOENGINE --direct=0 --verify=0 --bs=4K --iodepth=1024 --rw=write --group_reporting=1 --numjobs=$NR_THREADS | tee fio_write_${NR_THREADS}_${FILESIZE}_${IOENGINE}

                FlushDisk
                
                echo "READ EXPERIMENT @@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
                fio --name=nvme --directory=./fio-test --filename=test.txt --size=$FILESIZE --ioengine=$IOENGINE --direct=0 --verify=0 --bs=4K --iodepth=1024 --rw=read --group_reporting=1 --numjobs=$NR_THREADS | tee fio_read_${NR_THREADS}_${FILESIZE}_${IOENGINE}

                rm ./fio-test/*
        done
}

for ioengine in "${IOENGINES[@]}"
do
        FIOTEST $ioengine
done

#--ramp_time=2s --runtime=28s --time_based
