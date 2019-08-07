#!/bin/bash

TARGET=$OUTPUTDIR
#APP="rocksdb"
APP="redis"
#TYPE="SSD"
TYPE="NVM"

STATTYPE="APP"
STATTYPE="KERNEL"
ZPLOT="$NVMBASE/graphs/zplot"

## Scaling Kernel Stats Graph
let SCALE_KERN_GRAPH=100000

let SCALE_FILEBENCH_GRAPH=10

let INCR_KERN_BAR_SPACE=2
let INCR_FULL_BAR_SPACE=2


## declare an array variable
declare -a kernstat=("cache-hits" "cache-miss" "buff-hits" "buff-miss" "migrated")
declare -a pattern=("fillrandom" "readrandom" "fillseq" "readseq")

#declare -a devices=("SSD" "NVM")
declare -a devices=("NVM")

declare -a excludekernstat=("prefetch" "slowmem-only" "optimal" "obj-affinity-NVM1")
declare -a excludefullstat=("prefetch" "NVM1")

declare -a redispattern=("SET" "GET")


EXTRACT_KERNINFO() {

        APP=$1
        dir=$2
	j=$3
        APPFILE=$4
	awkidx=$5
	stattype=$6
	file=$APPFILE
        resultdir=$ZPLOT/data/kernstat
        mkdir -p $resultdir

        outfile=$(basename $dir)
        outputfile=$APP-$outfile"-"$stattype".data"
        rm -rf $resultdir/$outputfile
        rm -rf "num.data"

        if [ "$APP" == "redis" ]
	then
		target=$dir/$APP"-kernel.out"
	else
		target=$dir/$file
	fi

	if [ -f $target ]; then

		search="$"$awkidx
	        if [ "$APP" == "redis" ]
		then
			let val=`cat $target | grep "HeteroProcname" &> orig.txt && sed 's/\s/,/g' orig.txt > modified.txt && cat modified.txt | awk -F, -v OFS=, "BEGIN {SUM=0}; {SUM=SUM+$search}; END {print SUM}"`  
		else
			let val=`cat $target | grep "HeteroProcname" &> orig.txt && sed 's/\s/,/g' orig.txt > modified.txt && cat modified.txt | awk -F, -v OFS=, "{print $search}"`  
		fi

		let scaled_value=$val/$SCALE_KERN_GRAPH
		echo $scaled_value &> $APP"kern.data"
		((j++))
		echo $j &> "num.data"
		paste "num.data" $APP"kern.data" &> $resultdir/$outputfile
		rm -rf "num.data" $APP"kern.data"
	fi
}


PULL_RESULT() {

	APP=$1
	dir=$2
        j=$3      
	APPFILE=$4

	outputfile=$APP-$outfile".data"
	outfile=$(basename $dir)
	outputfile=$APP-$outfile".data"
	rm -rf $ZPLOT/data/$outputfile
	rm -rf "num.data"

	if [ -f $dir/$APPFILE ]; then


		if [ "$APP" = 'redis' ]; 
		then
			val=`cat $dir/$APPFILE | grep -a "ET" | grep $access":" | awk 'BEGIN {SUM=0}; {SUM+=$2}; END {printf "%5.3f\n", SUM}'`
			scaled_value=$(echo $val $SCALE_FILEBENCH_GRAPH | awk '{printf "%4.3f\n",$1*$2}')
			echo $scaled_value &> $APP".data"

		elif [  "$APP" = 'filebench' ]; 
		then
			val=`cat $dir/$APPFILE | grep "IO Summary:" | awk 'BEGIN {SUM=0}; {SUM=SUM+$6}; END {print SUM}'`
			scaled_value=$(echo $val $SCALE_FILEBENCH_GRAPH | awk '{printf "%4.3f\n",$1*$2}')
			echo $scaled_value &> $APP".data"
		else
			cat $dir/$APPFILE | grep "ops/sec" | awk 'BEGIN {SUM=0}; {SUM=SUM+$5}; END {print SUM}' &> $APP".data"
		fi
		((j++))
		echo $j &> "num.data"
		paste "num.data" $APP".data" &> $ZPLOT/data/$outputfile
		#echo "$ZPLOT/data/$outputfile"
		#cat $ZPLOT/data/$outputfile	
	fi
}



PULL_RESULT_PATTERN() {

	APP=$1
	dir=$2
        j=$3      
	APPFILE=$4
	access=$5
	resultdir=$ZPLOT/data/patern
	mkdir -p $resultdir

	outfile=$(basename $dir)
	outputfile=$APP-$outfile
	rm -rf $resultdir/$outputfile
	rm -rf "num.data"
	resultfile="$APP"-"$access.data"

	if [ -f $dir/$APPFILE ]; then

		file=$dir/$APPFILE
		
		if [ "$APP" = 'redis' ]; then
			cat $file | grep -a "$SEARCH" | grep $access":" | awk 'BEGIN {SUM=0}; {SUM+=$2}; END {printf "%5.3f\n", SUM}' &> $resultfile
		else
			if [ "$access" = 'readseq' ]; then
				cat $file | grep $access" " | awk 'BEGIN {SUM=0}; {SUM=SUM+$7}; END {print SUM/10}' &> $resultfile
			else
				cat $file | grep $access" " | awk 'BEGIN {SUM=0}; {SUM=SUM+$7}; END {print SUM}' &> $resultfile
			fi
		fi

		((j++))
		echo $j &> "num.data"
		paste "num.data" $resultfile &> $resultdir/$outputfile"-"$access".data"
		rm -rf "num.data" $resultfile
	fi
}

function EXCLUDE_DIR  {

	exlude=$1
	dir=$2
	local -n list=$3

	for check in "${list[@]}"
	do
		if [[ $dir == *"$check"* ]]; then
			((exlude++))	
		fi
	done
}



EXTRACT_BREAKDOWN_RESULT() {
	i=0
	j=0
	files=""
	rm $APP".data"

	APPFILE=""
	TYPE="NVM"

	for device in "${devices[@]}"
	do
		TYPE=$device
		APPFILE=$APP".out-"$device

		for accesstype in "${pattern[@]}"
		do
			for dir in $TARGET/*$device*
			do
				PULL_RESULT_PATTERN $APP $dir $j $basename $APPFILE $accesstype
			done
		done
		((j++))
	done
}




EXTRACT_KERNSTAT() {

	j=0
	exlude=0
	APP=$1
	rm $APP".data"
	rm "num.data"

	for device in "${devices[@]}"
	do
		TYPE=$device
		APPFILE=$APP".out-"$device

		 if [ $TYPE == "SSD" ]; then
			awkidx=10
		 else
			awkidx=9
		 fi

		if [ "$APP" == "redis" ]
		then
			awkidx=8
		fi

		for stattype in "${kernstat[@]}"
		do
			for dir in $TARGET/*$device*
			do
				exlude=0
				EXCLUDE_DIR $exlude $dir excludekernstat
				if [ $exlude -ge 1 ]; then
					echo "EXCLUDING" $dir
					continue;
				fi
				#echo $dir
				EXTRACT_KERNINFO $APP $dir $j $APPFILE $awkidx $stattype
			done
			((awkidx++))
			((awkidx++))
			j=$((j+$INCR_KERN_BAR_SPACE))
		done
	done
}


REDIS_CONSOLIDATE_RESULT() {

        dir=$1
        APP=$2
	let instances=4

        rm -rf $dir/$APP-"all.out"
        for file in $dir/$APP*.txt
        do
                search=$APP
                if [[ $file == *"$search"*".txt" ]];
                then
			rm -rf $dir/$APP"-all.out-"$device
                        cat $file | grep "ET:" &> tmp.txt
                        sed -i 's/\r/\n/g' tmp.txt
                        cat tmp.txt | grep "SET:" | tail -1 &>> $dir/$APP"-all.out-"$device
                        cat tmp.txt | grep "GET:" | tail -1 &>> $dir/$APP"-all.out-"$device
                fi
        done
        rm -rf tmp.txt

	for file in $dir/$APP".out-"*
	do
		if [ -f $file ]; then
			text="Currname\sredis-server"
			awkidx=10
			rm -rf $dir/$APP"-kernel.out"
			for i in $(seq 1 $instances);
			do
				 cat $file | sed 's/\[[^]]*\]//g' | sed 's/ Curr /Curr /g' |  grep $text$i | tail -1 &>> $dir/$APP"-kernel.out"
			done
		fi
	done

}



EXTRACT_REDIS_BREAKDOWN_RESULT() {
        j=0
        files=""
	APP=$1
        rm $APP".data"
        APPFILE=""

	for device in "${devices[@]}"
        do
                TYPE=$device
                APPFILE=$APP".out-"$device

		for dir in $TARGET/*$TYPE*
		do
			REDIS_CONSOLIDATE_RESULT $dir $APP
		done
	done

        for device in "${devices[@]}"
        do
                TYPE=$device
                APPFILE=$APP".out-"$device

		for accesstype in "${redispattern[@]}"
		do
			for dir in $TARGET/*$device*
			do
				PULL_RESULT_PATTERN $APP $dir $j $APP"-all.out-"$TYPE $accesstype
			done
			((j++))
		done
	done
}

EXTRACT_RESULT() {
	rm $APP".data"
	rm "num.data"
	exclude=0

	for device in "${devices[@]}"
	do
		TYPE=$device
		APPFILE=""

		for dir in $TARGET/*$TYPE*
		do
			exlude=0
			EXCLUDE_DIR $exlude $dir excludefullstat
			if [ $exlude -ge 1 ]; then
				echo "EXCLUDING" $dir
				continue;
			fi

			if [ "$APP" = 'redis' ]; then
				APPFILE=$APP"-all.out-"$TYPE
			else
				APPFILE=$APP".out-"$TYPE
			fi
			PULL_RESULT $APP $dir $j $APPFILE
		done
		j=$((j+$INCR_FULL_BAR_SPACE))
	done
}


EXTRACT_RESULT_REDIS() {
        files=""
	APP=$1
        rm $APP".data"
        APPFILE=""

	for device in "${devices[@]}"
        do
                TYPE=$device
                APPFILE=$APP".out-"$device

		for dir in $TARGET/*$TYPE*
		do
			REDIS_CONSOLIDATE_RESULT $dir $APP
		done
	done
	EXTRACT_RESULT
}

j=0
APP='filebench'
OUTPUTDIR="/users/skannan/ssd/NVM/appbench/output"
TARGET=$OUTPUTDIR
EXTRACT_RESULT "filebench"

OUTPUTDIR="/users/skannan/ssd/NVM/results/redis-results-july30th"
TARGET=$OUTPUTDIR
APP='redis'
EXTRACT_RESULT_REDIS "redis"


APP='rocksdb'
OUTPUTDIR="/users/skannan/ssd/NVM/appbench/output"
TARGET=$OUTPUTDIR
EXTRACT_RESULT "rocksdb"

cd $ZPLOT
python $NVMBASE/graphs/zplot/scripts/e-allapps-total.py
exit


EXTRACT_RESULT
cd $ZPLOT
python $NVMBASE/graphs/zplot/scripts/e-rocksdb-total.py
exit

EXTRACT_KERNSTAT "rocksdb"
cd $ZPLOT
python $NVMBASE/graphs/zplot/scripts/e-rocksdb-kernstat.py -o "e-rocksdb-kernstat" -a "rocksdb" -y 200 -r 40 -s "SSD"

EXTRACT_BREAKDOWN_RESULT
cd $ZPLOT
python $NVMBASE/graphs/zplot/scripts/e-rocksdb-breakdown.py
exit


EXTRACT_KERNSTAT "redis"
cd $ZPLOT
python $NVMBASE/graphs/zplot/scripts/e-rocksdb-kernstat.py -i "" -o "e-redis-kernstat" -a "redis" -y 80 -r 10 -s "SSD"

EXTRACT_REDIS_BREAKDOWN_RESULT "redis"
cd $ZPLOT
python $NVMBASE/graphs/zplot/scripts/e-redis-breakdown.py
exit


#EXTRACT_KERNSTAT





