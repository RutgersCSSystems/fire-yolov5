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


filesize=20 ##test file size in GB
PFETCH_SIZE=20 #5MB
NR_THREADS=1
#size of prefetch for each request
#declare -a prefetch_sizes=("5242880")
#declare -a prefetch_sizes=("10" "40" "128" "256" "1280" "25600" "131072" "262144" "2621440" "5242880")
#declare -a nr_threads=("1" "2" "4" "8" "16")
declare -a nr_threads=("1")
declare -a filesizes=("10" "20" "30" "40" "50" "60")


rm -rf bigfakefile.txt

#make SIZE=$filesize
#./bin/write


#for NR_THREADS in "${nr_threads[@]}"
for filesize in "${filesizes[@]}"
do
	echo "#################################"
	echo "$NR_THREADS to prefetch"
	
	make SIZE=$filesize NR_RA_PG=$PFETCH_SIZE NR_BG_THREADS=$NR_THREADS

	./bin/write

	FlushDisk

	#ENABLE_LOCK_STATS
	#./bin/read_os_smallpfetch
	/usr/bin/time -v ./bin/read_os_smallpfetch
	#dont_read_os_pfetch  read_noprefetch  read_onlyospfetch  read_onlypfetch  read_os_fullpfetch  read_os_smallpfetch  write
	#DISABLE_LOCK_STATS
	#cat /proc/lock_stat | awk '{print $6}' | grep -Eo '[0-9\.]+' | awk '{ sum += $1 } END { print sum }'
done
