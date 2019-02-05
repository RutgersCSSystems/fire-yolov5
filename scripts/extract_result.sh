#!/bin/bash
TARGET=$OUTPUTDIR

EXTRACT_RESULT() {
	for dir in $TARGET/*
	do
		#dir=$OUTPUTDIR
		echo $dir 

		echo "   "
		APP=graphchi
		if [ -f $dir/$APP ]; then
			grep "Elapsed" $dir/$APP | awk '{print "graphchi: " $8}'
		fi

		APP=db_bench
		if [ -f $dir/$APP ]; then
			cat $dir/$APP | grep "micros" | awk 'BEGIN {SUM=0}; {SUM=SUM+$7}; END {print "rocksdb: " SUM}'
		fi

		APP=fio
		if [ -f $dir/$APP ]; then
			cat $dir/$APP | grep "WRITE: bw=" | awk '{print $2}'| grep -o '[0-9]*' | awk '{sum += $1} END {print "fio: " sum}'
		fi

		APP=filebench
		if [ -f $dir/$APP ]; then
			cat $dir/$APP | grep "IO Summary:" | awk '{print "filebench:" $10}'
		fi
		#cat $dir/$APP | grep "bw=" | awk '{print $2}'| grep -o '[0-9]*' | awk '{sum += $1} END {print "fcreate: " sum}'

		APP=Metis
		if [ -f $dir/$APP ]; then
			grep "Real:" $dir/$APP | awk '{print "Metis: " $2}'
		fi

		APP=redis
		if [ -f $dir/$APP"1.txt" ]; then
			cat $dir/$APP* | grep -a "requests per second" | awk 'BEGIN {SUM=0}; {SUM+=$3}; END {printf "redis: %5.3f\n", SUM}'
		fi

		APP=memcached
		if [ -f $dir/$APP ]; then
			cat $dir/$APP | grep -a "ETS:" | tail -1 | awk 'BEGIN {SUM=0}; {SUM=$2+$4}; END {print "memcached: " SUM}'
		fi

		APP=leveldb
		if [ -f $dir/$APP ]; then
			awk 'BEGIN {SUM=0}; {SUM=SUM+$3}; END {printf "%.3f\n", SUM}' $dir/$APP
		fi
		echo "-------------------------"
	done
}

EXTRACT_INFO() {
	dir=$1
	APP=$2
	if [ -f $dir/$APP ]; then
		echo "----------------------------"$APP"----------------"
		cat $dir/$APP | grep "page_cache_hits" | awk '{sum += $9} END {print "page_cache_hits: " sum}'
		cat $dir/$APP | grep "page_cache_miss" | awk '{sum += $11} END {print "page_cache_miss: " sum}'
		cat $dir/$APP | grep "buff_page_hits" | awk '{sum += $13} END {print "buff_page_hits: " sum}'
		cat $dir/$APP | grep "buff_buffer_miss" | awk '{sum += $15} END {print "buff_buffer_miss: " sum}'
	fi
}

EXTRACT_INFO_OLD() {
	dir=$1
	APP=$2
	if [ -f $dir/$APP ]; then
		echo "----------------------------"$APP"----------------"
		cat $dir/$APP | grep "cache" | awk '{sum += $13} END {print "page_cache_hits: " sum}'
		cat $dir/$APP | grep "cache miss" | awk '{sum += $16} END {print "page_cache_miss: " sum}'
		cat $dir/$APP | grep "buffer page hits" | awk '{sum += $20} END {print "buff_page_hits: " sum}'
		cat $dir/$APP | grep "miss" | awk '{sum += $24} END {print "buff_buffer_miss: " sum}'
	fi
}

EXTRACT_KERNSTAT(){
	
	for dir in $TARGET/*
	do 
		echo $dir
		APP=db_bench 
		EXTRACT_INFO_OLD $dir $APP

		APP=redis
		EXTRACT_INFO_OLD $dir $APP

		APP=filebench
		EXTRACT_INFO_OLD $dir $APP
	done

}

#EXTRACT_RESULT
EXTRACT_KERNSTAT





