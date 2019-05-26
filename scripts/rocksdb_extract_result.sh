#!/bin/bash
TARGET=$OUTPUTDIR
APP="e-rocksdb-"

EXTRACT_RESULT() {

	i=0
	j=0
	files=""
	file1=""
	rm $APP".data"
	rm "num.data"

	for dir in $TARGET/*
	do
		#dir=$OUTPUTDIR
		echo $(basename $dir)
		outfile=$(basename $dir)
		APPFILE=db_bench.out
		if [ -f $dir/$APPFILE ]; then
			cat $dir/$APPFILE | grep "micros" | awk 'BEGIN {SUM=0}; {SUM=SUM+$5}; END {print SUM}' &> $APP".data"
			((j++))
			echo $j &> "num.data"
		fi
	        #files="$file1 output$i"	
		#file1=$files
		((i++))
		rm graphs/zplot/data/$APP$outfile".data"
		paste "num.data" $APP".data" &> graphs/zplot/data/$APP$outfile".data"
	done
	#echo $files

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

EXTRACT_RESULT
#EXTRACT_KERNSTAT

cd $NVMBASE/graphs/zplot/
python $NVMBASE/graphs/zplot/scripts/e-rocksdb.py




