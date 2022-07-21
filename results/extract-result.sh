#!/bin/bash
#set -x

TARGET=$OUTPUTDIR
#APP="rocksdb"
APP="redis"
#TYPE="SSD"
#TYPE="NVM"
TYPE=""

STATTYPE="APP"
STATTYPE="KERNEL"
ZPLOT="$NVMBASE/graphs/zplot"

## Scaling Kernel Stats Graph
let SCALE_KERN_GRAPH=100000
let SCALE_FILEBENCH_GRAPH=1
let SCALE_REDIS_GRAPH=1000
let SCALE_ROCKSDB_GRAPH=1
let SCALE_CASSANDRA_GRAPH=100
let SCALE_SPARK_GRAPH=50000



let INCR_KERN_BAR_SPACE=3
let INCR_BREAKDOWN_BAR_SPACE=2
let INCR_FULL_BAR_SPACE=1
let INCR_ONE_SPACE=1


## declare an array variable
#declare -a kernstat=("cache-miss" "buff-miss" "migrated")
#declare -a techarrcontextsensitivity=('slowmem-only' 'optimal-os-fastmem'  'naive-os-fastmem' 'slowmem-migration-only' 'slowmem-obj-affinity-prefetch')
#declare -a sensitive_arr=('APPSLOW-OSSLOW' 'APPFAST-OSFAST' 'APPFAST-OSSLOW' 'APPSLOW-OSFAST')
#declare -a techarrcontextsensitivity=('slowmem-only' 'optimal-os-fastmem'  'naive-os-fastmem' 'slowmem-migration-only' 'slowmem-obj-affinity-prefetch')
#declare -a pattern=("fillrandom" "readrandom" "fillseq" "readseq" "overwrite")
#declare -a configarrbw=("BW500" "BW1000" "BW2000" "BW4000")
#declare -a configarr=("BW1000")
#declare -a configarrcap=("CAP2048" "CAP4096" "CAP8192" "CAP10240")
#declare -a mechnames=('naive-os-fastmem' 'optimal-os-fastmem' 'slowmem-migration-only' 'slowmem-obj-affinity-nomig'  'slowmem-obj-affinity' 'slowmem-obj-affinity-net' 'slowmem-only')
#declare -a apparr=("SSD" "NVM")
#declare -a excludekernstat=("obj-affinity-NVM1")
#declare -a excludefullstat=('slowmem-obj-affinity-prefetch' 'slowmem-obj-affinity-net' 'NVM1')
#declare -a excludesensitivecontext=("NVM1" "obj-affinity-net")
#declare -a excludebreakdown=("optimal" "NVM1" "nomig" "naive" "affinity-net" "slowmem-only" "optimal")
#declare -a excluderedisbreakdown=("affinity-prefetch")
#declare -a redispattern=("SET" "GET")
#declare -a mech_redis_prefetch=('slowmem-obj-affinity' 'slowmem-obj-affinity-prefetch')
##use this for storing some state
#let slowmemhists=0

declare -a techarr=("Vanilla" "Cross_Naive" "CPBI" "CPNI" "CNI" "CPBV" "CPNV")

#APPlication Array for file bench
declare -a filesworkarr=("videoserver.f" "filemicro_seqread.f" "mongo.f" "fileserver.f" "randomread.f" "randomrw.f" "oltp.f")

#APPlication Array for file bench
declare -a rocksworkarr=("readseq" "readrandom")




PULL_RESULT() {
	APP=$1
	APPVAL=$2
        j=$3      
	APPFILE=$4
	ADDNUM=$5
	WORKLOAD=$6
	#GRAPHDATA=$5


	outfile=$(basename $dir)
	outputfile=$APP".data"

	#resultfile=$ZPLOT/data/$GRAPHDATA/$outputfile
	#mkdir -p $ZPLOT/data/$GRAPHDATA

	resultfile=$TARGET/$outfile/"GRAPH.DATA"
	#echo $resultfile

	rm -rf "num.tmp"
	##echo "$APPFILE"

	if [ -f $APPFILE ]; then

		if [ "$APP" = 'filebench' ]; 
		then
			
			val=`cat $APPFILE | grep "IO Summary:" | awk 'BEGIN {SUM=0}; {SUM=SUM+$6}; END {print SUM}'`
			scaled_value=$(echo $val $SCALE_FILEBENCH_GRAPH | awk '{printf "%4.0f\n",$1/$2}')
			echo $scaled_value &> $APP".data"

		elif [ "$APP" = 'ROCKSDB' ];
		then
                        val=`cat $APPFILE | grep "ops/sec" | awk 'BEGIN {SUM=0}; {SUM=SUM+$5}; END {print SUM}'`
                        scaled_value=$(echo $val $SCALE_ROCKSDB_GRAPH | awk '{printf "%4.0f\n",$1/$2}')
                        echo $scaled_value &> $APP".data"
		fi

		if [[ "$ADDNUM" -eq 0 ]]; then
			((j++))
			#echo $j &>> "num.tmp"

			if [ "$APPVAL" = "Cross_Naive" ]; then
			    APPVAL="CRNaive"
			fi
			echo $APPVAL &>> "num.tmp"
			paste "num.tmp" $APP".data" &>> $WORKLOAD
		else
			paste $APP".data" &>> $WORKLOAD
		fi
		#cat $resultfile
	fi
}



EXTRACT_RESULT() {
	rm $APP".data"
	rm "num.tmp"
	exclude=0
	ADD=$1
	dir=0
	let num=0;

	rm "$APP.DATA"


	for APPLICATION in "${apparr[@]}"
	do
		TYPE=$APPLICATION
		APPFILE=""
		dir=$TARGET/$APPLICATION

		rm "$APPLICATION"


		if [[ "$num" -eq 0 ]]; then
			echo "Index" > num.tmp
			echo $APPLICATION > APP.DATA
			paste num.tmp APP.DATA > $APPLICATION 
		else
			echo $APPLICATION > APP.DATA
			paste APP.DATA > $APPLICATION
		fi



		for APPVAL in "${techarr[@]}"
		#do
		#for APPFILE in $TARGET/*$APPLICATION*/*.out
		do
			APPFILE=$APPVAL".out"

			if [[ "$num" -eq 0 ]]; then
				PULL_RESULT $APP $APPVAL $j  $TARGET/$APPLICATION/$APPFILE $num "$APPLICATION"

			else
				PULL_RESULT $APP $APPVAL $j $TARGET/$APPLICATION/$APPFILE $num "$APPLICATION"
			fi
		done

		let "num=num+1"

		#done
	done
	j=$((j+$INCR_FULL_BAR_SPACE))

	VAR=""
	for APPLICATION in "${apparr[@]}"
	do
		  VAR+="${APPLICATION} "
	done

	rm $APP".data"
	rm "num.tmp"

	`paste $VAR &>> $APP.DATA`

	for APPLICATION in "${apparr[@]}"
	do
		  rm $APPLICATION
	done

}


j=0
APP='filebench'
TARGET="$OUTPUTDIR/filebench/workloads"
#echo $TARGET
apparr=("${filesworkarr[@]}")     
EXTRACT_RESULT "filebench"



j=0
APP='ROCKSDB'
TARGET="$OUTPUTDIR/ROCKSDB"
#echo $TARGET
apparr=("${rocksworkarr[@]}")
EXTRACT_RESULT "ROCKSDB"





#cd $ZPLOT
#python2.7 $NVMBASE/graphs/zplot/scripts/e-allapps-total.py
#exit

