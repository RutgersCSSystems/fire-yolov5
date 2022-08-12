#!/bin/bash
#set -x

TARGET=$OUTPUTDIR

OUTPUTPATH=$PWD

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
let SCALE_ROCKSDB_GRAPH=10000
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
declare -a rocksworkarr=("readseq" "readrandom" "readreverse" "readwhilewriting" "readwhilescanning")


#declare -a threadarr=("4" "8" "16" "32")
declare -a threadarr=("8")


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

	resultfile=$TARGET/$outfile/"GRAPH.DATA"
	#echo $resultfile
	echo "$APPFILE"

	if [ -f $APPFILE ]; then

		if [ "$APP" = 'filebench' ]; 
		then
			
			val=`cat $APPFILE | grep "IO Summary:" | awk 'BEGIN {SUM=0}; {SUM=SUM+$6}; END {print SUM}'`
			scaled_value=$(echo $val $SCALE_FILEBENCH_GRAPH | awk '{printf "%4.0f\n",$1/$2}')
			echo $scaled_value
			echo $scaled_value &>> $APPVAL".DATA"

		elif [ "$APP" = 'ROCKSDB' ];
		then
                        val=`cat $APPFILE | grep "ops/sec" | awk 'BEGIN {SUM=0}; {SUM=SUM+$5}; END {print SUM}'`
                        scaled_value=$(echo $val $SCALE_ROCKSDB_GRAPH | awk '{printf "%4.0f\n",$1/$2}')
                        echo $scaled_value &>> $APPVAL".DATA"
		fi
	fi
}



EXTRACT_RESULT() {
	rm $APP".data"
	exclude=0
	ADD=$1
	dir=0
	let num=0;



	for THREAD in "${threadarr[@]}"
	do

		rm "$APP.DATA"
		rm -rf num.tmpa
		rm -rf $APP"-THREADS-$THREAD".DATA

		for APPLICATION in "${apparr[@]}"
		do
			if [[ "$num" -eq 0 ]]; then
				echo "# reader" > num.tmp
				echo $APPLICATION >> num.tmp
				let "num=num+1"
			else
				echo $APPLICATION >> num.tmp
			fi
		done 
		let num=0;



		#for APPLICATION in "${apparr[@]}"
		for APPVAL in "${techarr[@]}"
		do
			TYPE=$APPLICATION
			APPFILE=""
			dir=$TARGET/$APPLICATION

			rm "$APPLICATION"

			echo $APPLICATION

			if [[ "$num" -eq 0 ]]; then
				echo $APPVAL > $APPVAL.DATA
				#paste num.tmp APP.DATA > $APPLICATION 
			#else
				#echo $APPVAL > APP.DATA
				#paste APP.DATA > $APPLICATION
			fi

			#cat $APPLICATION.DATA
			for APPLICATION in "${apparr[@]}"
			do
				APPFILE=$APPVAL".out"
				PULL_RESULT $APP $APPVAL $j $TARGET/$APPLICATION/$THREAD/$APPFILE $num "$APPLICATION"
			done
		done

		j=$((j+$INCR_FULL_BAR_SPACE))

		VAR=""
		for APPVAL in "${techarr[@]}"
		do
			  VAR+="${APPVAL}.DATA "
		done

		echo $VAR
		`paste "num.tmp" $VAR &>> $APP"-THREADS-$THREAD".DATA`

		python $SCRIPTS/graphs/rocksdb.py $OUTPUTPATH/$APP"-THREADS-$THREAD.DATA" $OUTPUTPATH/$APP"-$THREAD"

		rm "num.tmp"
		for APPVAL in "${techarr[@]}"
		do
			  rm $APPVAL".DATA"
		done
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
apparr=("${rocksworkarr[@]}")
EXTRACT_RESULT "ROCKSDB"







#cd $ZPLOT
#python2.7 $NVMBASE/graphs/zplot/scripts/e-allapps-total.py
#exit

