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
let SCALE_FILEBENCH_GRAPH=100
let SCALE_REDIS_GRAPH=1000
let SCALE_ROCKSDB_GRAPH=1000
let SCALE_CASSANDRA_GRAPH=100
let SCALE_SPARK_GRAPH=50000


let SCALE_SNAPPY_GRAPH=1

let INCR_KERN_BAR_SPACE=3
let INCR_BREAKDOWN_BAR_SPACE=2
let INCR_FULL_BAR_SPACE=1
let INCR_ONE_SPACE=1

let APPINTERVAL=1000
let YTITLE="Throughput OPS/sec"
let XTITLE='#. of threads'

#Just the declarations. You can customize 
#in the functions below
declare -a rocksworkarr=("multireadrandom")
declare -a rocksworkproxyarr=("multirrandom")

declare -a filesworkarr=("filemicro_seqread.f")
declare -a fileproxyarr=("seqread")

declare -a snappyworkarr=("fsize-20000")
declare -a snappyproxyarr=("200MB-files")

declare -a simplebenchworkarr=("read-pvt-seq" "read-shared-seq" "read-pvt-seq" "read-shared-seq")
declare -a simplebenchproxyarr=("pvt-seq" "shared-seq" "pvt-random" "shared-random")


declare -a threadarr=("16")

let graphmax=0

#APPlication Array for file bench
set_rocks_global_vars() {
	declare -a rocksworkarr=("readwhilescanning" "multireadrandom" "readseq" "readreverse" "readwhilewriting" "fillseq" "fillrandom")
	declare -a rocksworkproxyarr=("readscan" "multirrandom" "readseq" "readreverse" "readwrite" "fillseq" "fillrandom")
	declare -a threadarr=("16")
}


set_filebench_global_vars() {
	declare -a filesworkarr=("filemicro_seqread.f"  "randomread.f" "videoserver.f" "fileserver.f")
	declare -a fileproxyarr=("seqread"  "randread" "videoserve" "fileserve")
	declare -a threadarr=("16")
}

set_snappy_global_vars() {
	declare -a snappyworkarr=("fsize-20000" "fsize-40000" "fsize-80000" "fsize-100000")
	declare -a snappyproxyarr=("200MB-files" "400MB-files" "800MB-files" "1000MB-files")
	declare -a threadarr=("16")
}


set_simplebench_global_vars() {
	simplebenchworkarr=("read_pvt_seq" "read_shared_seq" "read_pvt_seq" "read_shared_seq")
	simplebenchproxyarr=("pvt-seq" "shared-seq" "pvt-random" "shared-random")

	simplebenchworkarr=("read_shared_seq_global_simple")
	simplebenchproxyarr=("shared-seq")

	threadarr=("1" "4" "8" "16" "32")
}

declare -a techarr=("Vanilla" "OSonly" "Cross_Info_sync" "CII" "CIP" "CIPI")
declare -a techarr=("Vanilla" "OSonly" "Cross_Info" "CII" "CIP" "CIPI")
declare -a techarrname=("APPonly" "OSonly" "CrossInfo" "CrossInfo[+OPT]" "CrossInfo[+predict]" "CrossInfo[+predict+OPT]")




GET_GRAPH_YMAX() {

	let currval=$1

	if [[ $currval > "$graphmax" ]]; then
		graphmax=$1
		#echo "$graphmax"
	fi
}


GENERATE_PYTHON_LIST() {

        export legendlist=${techarr[0]}
        for i in "${techarr[@]:1}"; do
           legendlist+=",$i"
        done
        echo $legendlist

        i=0
        export legendnamelist=${techarrname[0]}
        for i in "${techarrname[@]:1}"; do
           legendnamelist+=",$i"
        done
        echo $legendnamelist

	export ymax=$graphmax
	export yinterval=$APPINTERVAL 

	#echo "MAX graph value is $ymax"
	#export ytitledef='Throughput (OPS/sec) in 100x'
	export ytitledef=$YTITLE
	export xtitledef=$XTITLE
}




PULL_RESULT() {
	APP=$1
	APPVAL=$2
        THREAD=$3      

	APPFILE=$4
	#echo "APPFILE**" "$APPFILE"

	ADDNUM=$5
	WORKLOAD=$6
	#GRAPHDATA=$5


	outfile=$(basename $dir)
	outputfile=$APP".data"

	resultfile=$TARGET/$outfile/"GRAPH.DATA"

	if [ -f $APPFILE ]; then

		if [ "$APP" = 'filebench' ]; 
		then
			
			val=`cat $APPFILE | grep "IO Summary:" | awk 'BEGIN {SUM=0}; {SUM=SUM+$10}; END {print SUM}'`
			scaled_value=$(echo $val $SCALE_FILEBENCH_GRAPH | awk '{printf "%4.0f\n",$1/$2}')

		elif [ "$APP" = 'ROCKSDB' ];
		then
                        val=`cat $APPFILE | grep "ops/sec" | awk 'BEGIN {SUM=0}; {SUM=SUM+$5}; END {print SUM}'`
                        scaled_value=$(echo $val $SCALE_ROCKSDB_GRAPH | awk '{printf "%4.0f\n",$1/$2}')

                elif [ "$APP" = 'snappy' ];
                then
                        val=`cat $APPFILE | grep "Average throughput:" | awk 'BEGIN {SUM=0}; {SUM=SUM+$3}; END {print SUM}'`
                        scaled_value=$(echo $val $SCALE_SNAPPY_GRAPH | awk '{printf "%4.0f\n",$1/$2}')

                elif [ "$APP" = 'SIMPLEBENCH' ];
                then
                        val=`cat $APPFILE | grep "MB/sec" | awk 'BEGIN {SUM=0}; {SUM=SUM+$4}; END {print SUM}'`
                        scaled_value=$(echo $val $SCALE_SNAPPY_GRAPH | awk '{printf "%4.0f\n",$1/$2}')

                fi

		#echo $scaled_value $APPVAL".DATA"
		echo $scaled_value &>> $APPVAL".DATA"
		echo $scaled_value &>> $WORKLOAD-$APPVAL".DATA"
		#echo $WORKLOAD-$APPVAL".DATA"
		GET_GRAPH_YMAX $scaled_value
	fi
}



GRAPH_GEN_FIRSTCOL_MULTIAPPS() {

	rm -rf MULTIAPPS.tmp
	let num=0

	for APPLICATION in "${apparr[@]}"
	do
		echo ${proxyapparr[$num]}
		if [[ "$num" -eq 0 ]]; then

			echo "# reader" > MULTIAPPS.tmp
		fi
		echo ${proxyapparr[$num]} >> MULTIAPPS.tmp
		let "num=num+1"
	done 
}


GENERATE_GRAPH_MULTIAPPS() {

	threadval=$1
	rm -rf $OUTPUTPATH/$APP-THREADS-$threadval.DATA

	VAR=""
	for TECH in "${techarr[@]}"
	do
		  VAR+="${TECH}.DATA "
	done

	echo $VAR
	`paste "MULTIAPPS.tmp" $VAR &>> $APP"-THREADS-$threadval".DATA`


	GENERATE_PYTHON_LIST

	echo "python $SCRIPTS/graphs/$APP.py $OUTPUTPATH/$APP-THREADS-$threadval.DATA $OUTPUTPATH/$APP-$threadval"
	python $SCRIPTS/graphs/plot".py" $OUTPUTPATH/$APP"-THREADS-$threadval.DATA" $OUTPUTPATH/$APP"-$threadval"

	rm -rf "MULTIAPPS.tmp"

	for TECH in "${techarr[@]}"
	do
		rm -rf $TECH".DATA"
	done
}



GRAPH_GEN_FIRSTCOL_MULTITHREADS() {

	APP=$1
	let num=0

	rm -rf "$APP.DATA"
	rm -rf MULTITHREADS.tmp

	if [[ "$num" -eq 0 ]]; then

		echo "# reader" > MULTITHREADS.tmp
	fi
	let "num=num+1"


	for threadval in "${threadarr[@]}"
	do
		echo $threadval >> MULTITHREADS.tmp
	done 
}


GENERATE_GRAPH_MULTITHREADS() {

	APPNAME=$1
	APP=$2
	VAR=""
	echo "GENERATE_GRAPH_MULTITHREADS:" $APPNAME
	rm -rf $APPNAME"-THREADS.DATA"

	for TECH in "${techarr[@]}"
	do
		VAR+="$APPNAME-$TECH.DATA "
	done
	echo $VAR
	`paste MULTITHREADS.tmp $VAR &>> $APPNAME"-THREADS.DATA"`
	cat $APPNAME"-THREADS.DATA"
	VAR=""

	GENERATE_PYTHON_LIST

	echo "python $SCRIPTS/graphs/$APP.py $OUTPUTPATH/$APPNAME"-THREADS.DATA" $OUTPUTPATH/$APP-THREAD-Sensitivity"
	python $SCRIPTS/graphs/plot".py" $OUTPUTPATH/$APPNAME"-THREADS.DATA" $OUTPUTPATH/$APP"-THREAD-Sensitivity"

	for threadval in "${threadarr[@]}"
	do
		for TECH in "${techarr[@]}"
		do
		  	rm -rf "$APPNAME-$TECH.DATA"
		done

	done
}


EXTRACT_RESULT()  {

	rm -rf $APP".data"
	exclude=0
	ADD=$1
	dir=0
	let num=0;


	for THREAD in "${threadarr[@]}"
	do
		GRAPH_GEN_FIRSTCOL_MULTIAPPS


		for TECH in "${techarr[@]}"
		do
			let num=0;

			for appval in "${apparr[@]}"
			do
				if [[ "$num" -eq 0 ]]; then
					echo $TECH > $TECH.DATA
					num=$num+1
				fi

				TECHOUT=$TECH".out"
				PULL_RESULT $APP $TECH $THREAD "$TARGET/$appval/$THREAD/$TECHOUT" $num "$appval"
			done
		done
		GENERATE_GRAPH_MULTIAPPS $THREAD
	done
}


EXTRACT_RESULT_THREADS()  {

	rm -rf $APP".data"
	exclude=0
	ADD=$1
	dir=0
	let num=0;

	GRAPH_GEN_FIRSTCOL_MULTITHREADS $APP

	let num=0;

	for appval in "${apparr[@]}"
	do
		for TECH in "${techarr[@]}"
		do
			#appval=""
			let num=0;

			#echo "*******************************************************************************"
			for THREAD in "${threadarr[@]}"
			do
				if [[ "$num" -eq 0 ]]; then
					rm -rf $appval-$TECH".DATA"
					echo $TECH > $appval-$TECH".DATA"
					num=$num+1
				fi

				TECHOUT=$TECH".out"
				PULL_RESULT $APP $TECH $THREAD "$TARGET/$appval/$THREAD/$TECHOUT" $num "$appval"
			done
			#cat $appval-$TECH".DATA"
			#echo "*******************************************************************************"

		done
	done

	for APPLICATION in "${apparr[@]}"
	do
		GENERATE_GRAPH_MULTITHREADS $APPLICATION $APP
	done

}

MOVEGRAPHS() {
	mkdir graphs
	mkdir -p graphs/local/
	cp *.pdf graphs/
	cp *.pdf graphs/local/
}


APP='SIMPLEBENCH'
TARGET="$OUTPUTDIR/SIMPLEBENCH"

#set the arrays
set_simplebench_global_vars

let APPINTERVAL=1000
YTITLE='Throughput (MB/sec)'
XTITLE='#. of threads'
echo $TARGET
apparr=("${simplebenchworkarr[@]}")
proxyapparr=("${simplebenchproxyarr[@]}")
#EXTRACT_RESULT "SIMPLEBENCH"
#MOVEGRAPHS
EXTRACT_RESULT_THREADS "SIMPLEBENCH"
MOVEGRAPHS
exit



APP='snappy'
TARGET="$OUTPUTDIR/snappy"

#set the arrays
set_snappy_global_vars

let APPINTERVAL=1000
YTITLE='Throughput (MB/sec)'
XTITLE='#. of threads'
echo $TARGET
apparr=("${snappyworkarr[@]}")
proxyapparr=("${snappyproxyarr[@]}")
EXTRACT_RESULT "snappy"
MOVEGRAPHS
#EXTRACT_RESULT_THREADS "snappy"
#MOVEGRAPHS
exit



APP='ROCKSDB'
TARGET="$OUTPUTDIR/ROCKSDB"

#set the arrays
set_rocks_global_vars

apparr=("${rocksworkarr[@]}")
proxyapparr=("${rocksworkproxyarr[@]}")

let APPINTERVAL=1000
YTITLE='Throughput (OPS/sec) in 100x'
echo $TARGET
XTITLE='Workloads'
EXTRACT_RESULT "ROCKSDB"
MOVEGRAPHS
XTITLE='#. of threads'
#EXTRACT_RESULT_THREADS "ROCKSDB"
MOVEGRAPHS
exit









APP='filebench'
TARGET="$OUTPUTDIR/filebench/workloads"
#echo $TARGET
apparr=("${filesworkarr[@]}")     
proxyapparr=("${fileproxyarr[@]}")
EXTRACT_RESULT "filebench"
exit









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

