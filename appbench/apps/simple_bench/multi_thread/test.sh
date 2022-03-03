#!/bin/bash

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sleep 5
}

ENABLE_LOCK_STATS()
{
	sudo sh -c "echo 0 > /proc/lock_stat"
	sudo sh -c "echo 1 > /proc/sys/kernel/lock_stat"
}

DISABLE_LOCK_STATS()
{
	sudo sh -c "echo 0 > /proc/sys/kernel/lock_stat"
}


filesize=60 ##test file size in GB
PFETCH_SIZE=20 #5MB
NR_THREADS=1
#size of prefetch for each request
#declare -a prefetch_sizes=("5242880")
#declare -a prefetch_sizes=("10" "40" "128" "256" "1280" "25600" "131072" "262144" "2621440" "5242880")
#declare -a nr_threads=("1" "2" "4" "8" "16")
declare -a nr_threads=("1" "2" "4" "8" "16")
#declare -a filesizes=("10" "20" "30" "40" "50" "60")
declare -a filesizes=("60")


#rm -rf bigfakefile*

#make SIZE=$filesize
#./bin/write


#for NR_THREADS in "${nr_threads[@]}"
for filesize in "${filesizes[@]}"
do
	echo "#################################"
	echo "$filesize GB to prefetch"
	
	make SIZE=$filesize NR_RA_PG=$PFETCH_SIZE NR_BG_THREADS=$NR_THREADS

     rm -rf bigfakefile*
	./bin/write

	FlushDisk

	#ENABLE_LOCK_STATS
	echo "@@@@@@@@@Read NO Prefetch"
	./bin/read_nopfetch
	FlushDisk

	echo "@@@@@@@@@Read OS Prefetch"
	./bin/read_onlyospfetch
	FlushDisk

	echo "@@@@@@@@@Read small prefetch READAHEAD noOS"
	./bin/read_noos_smallpfetch
	FlushDisk

	echo "@@@@@@@@@Read full prefetch READAHEAD noOS"
	./bin/read_noos_fullpfetch
	FlushDisk

	echo "@@@@@@@@@Read small prefetch READ noOS"
	./bin/read_noos_smallpfetch_read
	FlushDisk

	echo "@@@@@@@@@Read small prefetch PREAD_RA noOS"
	./bin/read_noos_smallpfetch_preadra
	FlushDisk

	echo "@@@@@@@@@Seq prefetch PREAD_RA noOS"
	./bin/preadra_noos_seq
     FlushDisk
	
	#echo "@@@@@@@@@Read small prefetch READ 16BG"
	#make SIZE=$filesize NR_RA_PG=$PFETCH_SIZE NR_BG_THREADS=16 > /dev/null
	#FlushDisk

     #./bin/read_os_smallpfetch_read
	#/usr/bin/time -v ./bin/read_os_smallpfetch
	#DISABLE_LOCK_STATS
	#cat /proc/lock_stat | awk '{print $6}' | grep -Eo '[0-9\.]+' | awk '{ sum += $1 } END { print sum }'
done
