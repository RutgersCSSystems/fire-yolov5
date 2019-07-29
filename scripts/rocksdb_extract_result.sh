#!/bin/bash
TARGET=$OUTPUTDIR
APP="rocksdb"
TYPE="SSD"

STATTYPE="APP"
STATTYPE="KERNEL"
ZPLOT="$NVMBASE/graphs/zplot"

## declare an array variable
declare -a arr=("cache-hits" "cache-miss" "buff-hits" "buff-miss" "migrated")


EXTRACT_KERNINFO() {
	dir=$1
	APP=$2
	awkidx=10

	if [ -f $dir/$APP ]; then

	for term in "${arr[@]}"
		do
			echo "----------------------------"$APP"----------------"
			search="$"$awkidx
			echo $search
			#cat $dir/$APP | grep $term | awk -v myvar="$search" '{sum += myvar } END {print "page_cache_hits: " sum}'
			cat $dir/$APP | grep Currname | awk -v myvar="$search" '{sum += myvar } END {print "page_cache_hits: " sum}'

			#cat $dir/$APP | grep "page_cache_hits" | awk '{sum += $9} END {print "page_cache_hits: " sum}'
			#cat $dir/$APP | grep "page_cache_miss" | awk '{sum += $11} END {print "page_cache_miss: " sum}'
			#cat $dir/$APP | grep "buff_page_hits" | awk '{sum += $13} END {print "buff_page_hits: " sum}'
			#cat $dir/$APP | grep "buff_buffer_miss" | awk '{sum += $15} END {print "buff_buffer_miss: " sum}'
			((awkidx++))
			((awkidx++))
		done
	fi
	
	
}



PULL_RESULT() {

	APP=$1
	dir=$2
        j=$3      
	basename=$4
	APPFILE=$5

	outputfile=$APP-$outfile".data"
	outfile=$(basename $dir)
	outputfile=$APP-$outfile".data"
	rm -rf $ZPLOT/data/$outputfile
	rm -rf "num.data"

	if [ -f $dir/$APPFILE ]; then
		#echo $dir/$APPFILE
		cat $dir/$APPFILE | grep "micros" | awk 'BEGIN {SUM=0}; {SUM=SUM+$7}; END {print SUM}' &> $APP".data"
		((j++))
		echo $j &> "num.data"
		paste "num.data" $APP".data" &> $ZPLOT/data/$outputfile
		#echo $ZPLOT/data/$outputfile
	fi
}


declare -a pattern=("fillrandom" "readrandom" "fillseq" "readseq")
#declare -a pattern=("fillrandom")


PULL_RESULT_PATTERN() {

	APP=$1
	dir=$2
        j=$3      
	basename=$4
	APPFILE=$5
	access=$6
	resultdir=$ZPLOT/data/patern
	mkdir -p $resultdir

	outfile=$(basename $dir)
	outputfile=$APP-$outfile
	rm -rf $resultdir/$outputfile
	rm -rf "num.data"
	resultfile="$APP"-"$access.data"

	if [ -f $dir/$APPFILE ]; then

		if [ "$access" = 'readseq' ]; then
			cat $dir/$APPFILE | grep $access" " | awk 'BEGIN {SUM=0}; {SUM=SUM+$7}; END {print SUM/10}' &> $resultfile
		else
			cat $dir/$APPFILE | grep $access" " | awk 'BEGIN {SUM=0}; {SUM=SUM+$7}; END {print SUM}' &> $resultfile
		fi
		((j++))
		echo $j &> "num.data"
		paste "num.data" $resultfile &> $resultdir/$outputfile"-"$access".data"
		echo $resultdir/$outputfile"-"$access".data"
		rm -rf "num.data" $resultfile
	fi
}


EXTRACT_BREAKDOWN_RESULT() {
	i=0
	j=0
	files=""
	rm $APP".data"

	for accesstype in "${pattern[@]}"
	do
		TYPE="NVM"
		for dir in $TARGET/*
		do
		 if [[ $dir = *"NVM"* ]]; 
		 then
			APPFILE=rocksdb.out-NVM
			#PULL_RESULT_PATTERN $APP $dir $j $basename $APPFILE $accesstype
		fi
		done

		APPFILE=""
		TYPE="SSD"
		for dir in $TARGET/*
		do
		if [[ $dir == *"SSD"* ]];
		 then
			#echo $dir
			APPFILE=rocksdb.out-SSD
			#PULL_RESULT $APP $dir $j $basename $APPFILE
			PULL_RESULT_PATTERN $APP $dir $j $basename $APPFILE $accesstype
		fi
		done
		((j++))
	done
}


EXTRACT_RESULT() {

	i=0
	j=0
	files=""
	file1=""
	rm $APP".data"
	rm "num.data"

	TYPE="NVM"
	for dir in $TARGET/*
	do
	 if [[ $dir = *"NVM"* ]]; 
 	 then
		APPFILE=rocksdb.out-NVM
		#EXTRACT_KERNINFO $dir $APPFILE
		PULL_RESULT $APP $dir $j $basename $APPFILE
	fi
	done

	APPFILE=""
	TYPE="SSD"
	for dir in $TARGET/*
	do
	if [[ $dir == *"SSD"* ]];
	 then
		APPFILE=rocksdb.out-SSD
		#PULL_RESULT $APP $dir $j $basename $APPFILE
		PULL_RESULT_PATTERN $APP $dir $j $basename $APPFILE
	fi
	done
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
EXTRACT_BREAKDOWN_RESULT
#cd $NVMBASE/graphs/zplot/
#python $NVMBASE/graphs/zplot/scripts/e-rocksdb.py
cd $ZPLOT
python $NVMBASE/graphs/zplot/scripts/e-rocksdb-breakdown.py
#EXTRACT_KERNSTAT





