#!/bin/bash
TARGET=$OUTPUTDIR
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
