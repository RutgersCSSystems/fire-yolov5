#!/bin/bash

##Tests fio read performance with increasing number of threads

#set -x

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sleep 5
}

FILESIZE=16

declare -a nr_threads=("16" "2" "4" "8")

for NPROC in "${nr_threads[@]}"
do
	echo "######################################"
        echo "$NPROC threads"
	SIZE=`echo "$FILESIZE/$NPROC" | bc`
	NAME=NVME_${NPROC}
	COMMAND="fio --name=$NAME --directory=./fio-test --ioengine=psync --rw=read --bs=4k --numjobs=$NPROC --size=${SIZE}g --iodepth=1 --fadvise_hint=0 --thread"

	FlushDisk
	echo "VANILLA"
	export LD_PRELOAD=""
	$COMMAND | grep "READ"
	FlushDisk

	FlushDisk
	echo "#######"
	echo "CNI"
	export LD_PRELOAD=/usr/lib/lib_CNI.so
	$COMMAND
	export LD_PRELOAD=""
	FlushDisk

	exit

	echo "Vanilla Naive RA IOOPT"
	export LD_PRELOAD=/usr/lib/lib_VRAI.so
	$COMMAND | grep "READ"
	export LD_PRELOAD=""
	FlushDisk
done
set +x
