#!/bin/bash

FlushDisk()
{
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
	sudo dmesg --clear
	sleep 5
}


KB=1024
MB=`echo "1024*$KB" | bc`
GB=`echo "1024*$MB" | bc`


#./write

#for CACHE in $(seq 10 10 60)
#do
CACHE=$1
	echo "APP CACHE limit = $CACHE GB"
	FlushDisk
	#export APPCACHELIMIT=`echo "$CACHE*$GB" | bc`
	CACHE_BYTES=`echo "$CACHE*$GB" | bc`
	#export LD_PRELOAD=/usr/lib/libcache_lim_ospred.so

	#/read_onlyos
	#./test_read
	./test_readahead $CACHE_BYTES

	export LD_PRELOAD=""
	free -h
	dmesg
	echo "################"
	FlushDisk
#done
