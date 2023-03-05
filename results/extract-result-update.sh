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
GRAPHPYTHON="plot.py"

## Scaling Kernel Stats Graph
let SCALE_KERN_GRAPH=100000
let SCALE_FILEBENCH_GRAPH=100
let SCALE_REDIS_GRAPH=1000
let SCALE_ROCKSDB_GRAPH=1
let SCALE_CASSANDRA_GRAPH=100
let SCALE_SPARK_GRAPH=50000
let SCALE_YCSB_GRAPH=10000


let SCALE_SNAPPY_GRAPH=10
let SCALE_SIMPLEBENCH_GRAPH=1

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

declare -a rocksycsbarr=("multireadrandom")
declare -a rocksycsbproxyarr=("multirrandom")


declare -a filesworkarr=("filemicro_seqread.f")
declare -a fileproxyarr=("seqread")

declare -a snappyworkarr=("fsize-20000")
declare -a snappyproxyarr=("200MB-files")

declare -a simplebenchworkarr=("read-pvt-seq" "read-shared-seq" "read-pvt-seq" "read-shared-seq")
declare -a simplebenchproxyarr=("pvt-seq" "shared-seq" "pvt-random" "shared-random")


declare -a threadarr=("16")

let graphmax=0

declare -a techarr=("Vanilla" "OSonly" "Cross_Info_sync" "CII" "CIP" "CIPI")
#declare -a techarr=("Vanilla" "OSonly" "Cross_Info" "CII" "CIP" "CIPI")
#declare -a techarrname=("APPonly" "OSonly" "CrossInfo[+fetchall]" "CrossInfo[+fetchall+OPT]" "CrossInfo[+predict]" "CrossInfo[+predict+OPT]")


declare -a techarr=("Vanilla" "OSonly" "CIP" "CIPI" "CII")
declare -a techarrname=("APPonly" "OSonly" "CrossInfo[+predict]" "CrossInfo[+predict+OPT]" "CrossInfo[+fetchall+OPT]")



#APPlication Array for file bench
set_rocks_global_vars() {

	techarr=("Vanilla" "OSonly" "CIP" "CIPI" "CII")
	techarrname=("APPonly" "OSonly" "CrossInfo[+predict]" "CrossInfo[+predict+OPT]" "CrossInfo[+fetchall+OPT]")

	#techarr=("Vanilla" "OSonly" "CII_sync" "CII" "CIP_sync" "CIP" "CPBI_sync"  "CPBI")
	#techarrname=("APPonly" "OSonly" "+fetchall+sync" "+fetchall" "+pred+sync" "+pred" "+pred+OPT+budget+sync" "+pred+OPT+budget")

	#rocksworkarr=("readwhilescanning" "multireadrandom" "readseq" "readreverse" "readwhilewriting" "fillseq" "fillrandom")
	#rocksworkproxyarr=("readscan" "multirrandom" "readseq" "readreverse" "readwrite" "fillseq" "fillrandom")

	rocksworkarr=("readseq" "readreverse" "readwhilescanning" "multireadrandom")
	rocksworkproxyarr=("readseq" "readreverse" "readscan" "multirrandom")

	threadarr=("16")
}


set_rocks_thread_impact_global_vars() {
	rocksworkarr=("readseq")
	rocksworkproxyarr=("rseq")
	threadarr=("8" "16" "32")
}


set_rocks_memimpact_impact_global_vars() {
	rocksworkarr=("readseq")
	rocksworkproxyarr=("rseq")
	memfractarr=("6" "4" "2")
	memfractarrproxy=("6" "4" "2")
	threadarr=("16")

	techarr=("Vanilla" "OSonly" "Cross_Info_sync" "CPBI")
	techarrname=("APPonly" "OSonly" "CrossInfo[+fetchall]" "CrossInfo[+predict+OPT+budget]")
}

set_snappy_memimpact_impact_global_vars() {

        snappyworkarr=("100")
        snappyproxyarr=("Snappy-100MB")
        memfractarr=("6" "4" "2" "1")
        memfractarrproxy=("6" "4" "2" "1")

        threadarr=("8")

        techarr=("Vanilla" "OSonly" "Cross_Info" "CIPI" "CPBI" )
        techarrname=("APPonly" "OSonly" "CrossInfo[+fetchall]" "CrossInfo[+predict+OPT]"  "CrossInfo[+predict+OPT+budget]")
}




set_rocks_ycsb_global_vars() {
	rocksycsbarr=("ycsbwkldb" "ycsbwkldc" "ycsbwkldd" "ycsbwklde")
	rocksycsbproxyarr=("work-b" "work-c" "work-d" "work-e")
	threadarr=("16")
}



set_filebench_global_vars() {
	filesworkarr=("filemicro_seqread.f" "randomread.f" "mongo.f" "fivestreamread.f")
	fileproxyarr=("seqread"  "randread" "mongo" "streamread")
	threadarr=("16")
}

set_snappy_global_vars() {
	declare -a snappyworkarr=("fsize-20000" "fsize-40000" "fsize-80000" "fsize-100000")
	declare -a snappyproxyarr=("200MB-files" "400MB-files" "800MB-files" "1000MB-files")
	declare -a threadarr=("16")
}


set_simplebench_global_vars() {
	simplebenchworkarr=("read_pvt_seq" "read_shared_seq" "read_pvt_seq" "read_shared_seq")
	simplebenchproxyarr=("pvt-seq" "shared-seq" "pvt-random" "shared-random")

	simplebenchworkarr=("read_shared_seq_global_simple" "read_pvt_seq_global")
	simplebenchproxyarr=("shared-seq" "pvt-seq")

	threadarr=("1" "8" "16" "32")
}

set_simplebench_read_size_sensitivity_global_vars() {

	simplebenchworkarr=("read_pvt_seq-READSIZE-4" "read_pvt_seq-READSIZE-128" "read_pvt_rand-READSIZE-4" "read_pvt_rand-READSIZE-128" "read_shared_seq-READSIZE-4" "read_shared_seq-READSIZE-128" "read_shared_rand-READSIZE-4" "read_shared_rand-READSIZE-128")
	simplebenchproxyarr=("privseq-4" "privseq-128" "privrand-4" "privrand-128" "shareseq-4" "shareseq-128" "sharerand-4" "sharerand-128")

	#simplebenchworkarr=("read_pvt_seq-READSIZE-4" "read_pvt_rand-READSIZE-4"  "read_shared_seq-READSIZE-4" "read_shared_rand-READSIZE-4" "read_pvt_seq-READSIZE-32" "read_pvt_rand-READSIZE-32" "read_shared_seq-READSIZE-32" "read_shared_rand-READSIZE-32")
	#simplebenchproxyarr=("privseq-4" "privrand-4"  "shareseq-4" "sharerand-4" "privseq-32" "privrand-32" "shareseq-32" "sharerand-32")

	simplebenchworkarr=("read_pvt_seq-READSIZE-4" "read_pvt_rand-READSIZE-4" "read_shared_seq-READSIZE-4"  "read_shared_rand-READSIZE-4") 
	simplebenchproxyarr=("private-seq" "private-rand" "shared-seq" "shared-rand")

	threadarr=("16")
}




#declare -a techarr=("Vanilla" "OSonly" "CIP" "CII")
#declare -a techarrname=("APPonly" "OSonly" "CrossInfo[+predict]" "CrossInfo[+fetchall+OPT]")


GET_GRAPH_YMAX() {

	let currval=$1
	let max=$graphmax

	if [[ $currval -gt $max ]]; then
		let graphmax=$currval
	fi
	#echo "CURRVAL: $currval" "GRAPHMAX:" "$graphmax"
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

	echo $APPFILE

	if [ -f $APPFILE ]; then

		if [ "$APP" = 'filebench' ]; 
		then
			
			val=`cat $APPFILE | grep "IO Summary:" | awk 'BEGIN {SUM=0}; {SUM=SUM+$10}; END {print SUM}'`
			scaled_value=$(echo $val $SCALE_FILEBENCH_GRAPH | awk '{printf "%4.0f\n",$1/$2}')

		elif [ "$APP" = 'ROCKSDB' ];
		then
                        val=`cat $APPFILE | grep "ops/sec" | awk 'BEGIN {SUM=0}; {SUM=SUM+$5}; END {print SUM}'`
                        scaled_value=$(echo $val $SCALE_ROCKSDB_GRAPH | awk '{printf "%4.0f\n",$1/$2}')

		elif [ "$APP" = 'YCSB-ROCKSDB' ];
		then
                        val=`cat $APPFILE | grep "ops/sec" | awk 'BEGIN {SUM=0}; {SUM=SUM+$5}; END {print SUM}'`
                        scaled_value=$(echo $val $SCALE_YCSB_GRAPH | awk '{printf "%4.0f\n",$1/$2}')

                elif [ "$APP" = 'snappy' ];
                then
                        val=`cat $APPFILE | grep "Average throughput:" | awk 'BEGIN {SUM=0}; {SUM=SUM+$3}; END {print SUM}'`
                        scaled_value=$(echo $val $SCALE_SNAPPY_GRAPH | awk '{printf "%4.0f\n",$1/$2}')

                elif [ "$APP" = 'SIMPLEBENCH' ];
                then
                        val=`cat $APPFILE | grep "READ.*Bandwidth.*" | awk 'BEGIN {SUM=0}; {SUM=SUM+$4}; END {print SUM}'`
                        scaled_value=$(echo $val $SCALE_SIMPLEBENCH_GRAPH | awk '{printf "%4.0f\n",$1/$2}')

                elif [ "$APP" = 'SIMPLEBENCH-READSIZE-EXP' ];
                then
                        val=`cat $APPFILE | grep "READ.*Bandwidth.*" | awk 'BEGIN {SUM=0}; {SUM=SUM+$4}; END {print SUM}'`
                        scaled_value=$(echo $val $SCALE_SIMPLEBENCH_GRAPH | awk '{printf "%4.0f\n",$1/$2}')
                fi

		#echo $scaled_value $APPVAL".DATA"
		echo $scaled_value &>> $APPVAL".DATA"
		echo $scaled_value &>> $WORKLOAD-$APPVAL".DATA"
		#echo $WORKLOAD-$APPVAL".DATA" 
		#cat $WORKLOAD-$APPVAL".DATA"
		#echo "***************************"
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

	rm -rf "MULTIAPPS.tmp"

	for TECH in "${techarr[@]}"
	do
		rm -rf $TECH".DATA"
	done

	GENERATE_PYTHON_LIST

	echo "python $SCRIPTS/graphs/$APP.py $OUTPUTPATH/$APP-THREADS-$threadval.DATA $OUTPUTPATH/$APP-$threadval"
	python $SCRIPTS/graphs/plot".py" $OUTPUTPATH/$APP"-THREADS-$threadval.DATA" $OUTPUTPATH/$APP"-$threadval"


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

GRAPH_GEN_FIRSTCOL_MEMSENSITIVE() {

	APP=$1
	let num=0

	rm -rf "$APP.DATA"
	rm -rf MULTITHREADS.tmp

	if [[ "$num" -eq 0 ]]; then

		echo "# reader" > MULTITHREADS.tmp
	fi
	let "num=num+1"

	for memfracval in "${memfractarr[@]}"
	do
		echo $memfracval >> MULTITHREADS.tmp
	done 
}




GENERATE_GRAPH_MULTITHREADS() {

	APPNAME=$1
	APP=$2
	workload=$3

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

	echo "python $SCRIPTS/graphs/$GRAPHPYTHON $OUTPUTPATH/$APPNAME"-THREADS.DATA" $OUTPUTPATH/$APP-THREAD-Sensitivity"
	python $SCRIPTS/graphs/$GRAPHPYTHON $OUTPUTPATH/$APPNAME"-THREADS.DATA" $OUTPUTPATH/$APP"-$workload-THREAD-Sensitivity"

	for threadval in "${threadarr[@]}"
	do
		for TECH in "${techarr[@]}"
		do
		  	rm -rf "$APPNAME-$TECH.DATA"
		done

	done
}


GENERATE_GRAPH_MEMSENSITIVE() {

	APPNAME=$1
	APP=$2
	workload=$3
	MEMFRAC=$4

	VAR=""
	echo "GENERATE_GRAPH_MEMSENSITIVE:" $APPNAME
	rm -rf $APPNAME"-MEMFRAC.DATA"

	for TECH in "${techarr[@]}"
	do
		VAR+="$APPNAME-$TECH.DATA "
	done

	echo $VAR

	`paste MULTITHREADS.tmp $VAR &>> $APPNAME"-MEMFRAC.DATA"`
	cat $APPNAME"-MEMFRAC.DATA"
	VAR=""

	GENERATE_PYTHON_LIST

	echo "python $SCRIPTS/graphs/$GRAPHPYTHON $OUTPUTPATH/$APPNAME"-THREADS.DATA" $OUTPUTPATH/$APP-MEMFRAC-Sensitivity"
	python $SCRIPTS/graphs/$GRAPHPYTHON $OUTPUTPATH/$APPNAME"-MEMFRAC.DATA" $OUTPUTPATH/$APP"-$workload-MEMFRAC-Sensitivity"

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

				echo "TECH ARR:" $appval
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

		for APPLICATION in "${apparr[@]}"
		do
			GENERATE_GRAPH_MULTITHREADS $APPLICATION $APP $appval
		done
	done
}


EXTRACT_RESULT_MEMSENSITIVE()  {

	rm -rf $APP".data"
	exclude=0
	ADD=$1
	dir=0
	let num=0;

	GRAPH_GEN_FIRSTCOL_MEMSENSITIVE $APP

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
				for MEMFRAC in "${memfractarr[@]}"
				do
					if [[ "$num" -eq 0 ]]; then
						rm -rf $appval-$TECH".DATA"
						echo $TECH > $appval-$TECH".DATA"
						num=$num+1
					fi
					TECHOUT=$TECH".out"
					PULL_RESULT $APP $TECH $THREAD "$TARGET/MEMFRAC$MEMFRAC/$appval/$THREAD/$TECHOUT" $num "$appval"
				done
			done
			#echo "*******************************************************************************"
		done

		for APPLICATION in "${apparr[@]}"
		do
			GENERATE_GRAPH_MEMSENSITIVE $APPLICATION $APP $appval
		done

	done
}




UPDATE_PAPER() {

	INPUTPATH=$1
	mkdir -p $PAPERGRAPHS
	cp -r $INPUTPATH $PAPERGRAPHS/
	cd $PAPERGRAPHS
	git add $PAPERGRAPHS
	git add $PAPERGRAPHS/*
	git pull
	git commit -am "adding current results for $APP"
	git push origin 
}

MOVEGRAPHS() {

	GRAPHDATA="graphs/$APP$APPPREFIX"
	GRAPHLOCALDATA="graphs/local/$APP$APPPREFIX"

	echo $GRAPHLOCALDATA

	mkdir -p $GRAPHDATA
	mkdir -p $GRAPHLOCALDATA

	cp *.pdf $GRAPHDATA/
	cp *.pdf $GRAPHLOCALDATA/

	UPDATE_PAPER $GRAPHDATA
}

MOVEGRAPHS-MEMSENSITIVE() {

	cp *.pdf graphs/$APP"$APPPREFIX"/"MEMFRAC"
	cp *.pdf graphs/local/$APP"$APPPREFIX"/"MEMFRAC"
	UPDATE_PAPER "graphs/local/$APP$APPPREFIX"/"MEMFRAC"
}


MOVEGRAPHS_ROCKSB() {

	OUTPUT=graphs/local/ROCKSDB18/$APP"$APPPREFIX"
	mkdir -p $OUTPUT
	cp *.pdf $OUTPUT

	UPDATE_PAPER $OUTPUT
}

MOVEGRAPHS_SIMPLEBENCH() {
	OUTPUT=graphs/local/SIMPLEBENCH-OCT18/$APP"$APPPREFIX"
	mkdir -p $OUTPUT
	cp *.pdf $OUTPUT

	UPDATE_PAPER $OUTPUT
}



export APPPREFIX="20M-KEYS"
APP='ROCKSDB'
TARGET="$OUTPUTDIR/$APP/$APPPREFIX"
#set the arrays
set_rocks_global_vars
apparr=("${rocksworkarr[@]}")
proxyapparr=("${rocksworkproxyarr[@]}")
let scalefactor=$SCALE_YCSB_GRAPH
let APPINTERVAL=500000
YTITLE='Throughput (OPS/sec) in '$SCALE_ROCKSDB_GRAPH'x'
echo $TARGET
XTITLE='Workloads'

export GRAPHPYTHON="plot.py"
EXTRACT_RESULT "ROCKSDB"
MOVEGRAPHS
exit


APP='SIMPLEBENCH'

TARGET="$OUTPUTDIR/SIMPLEBENCH"
export APPPREFIX="-READSIZE-EXP"
#set the arrays
set_simplebench_read_size_sensitivity_global_vars


let APPINTERVAL=2000
YTITLE='Throughput (MB/sec) in $SCALE_SIMPLEBENCH_GRAPHx'
XTITLE="Sequential and Random Access Patterns and Access Sizes in Pages"
echo $TARGET
apparr=("${simplebenchworkarr[@]}")
proxyapparr=("${simplebenchproxyarr[@]}")
EXTRACT_RESULT "SIMPLEBENCH"
MOVEGRAPHS_SIMPLEBENCH

#EXTRACT_RESULT_THREADS "SIMPLEBENCH-READSIZE-EXP"
#MOVEGRAPHS
exit








#MOVEGRAPHS
XTITLE='#. of threads'
set_rocks_thread_impact_global_vars
apparr=("${rocksworkarr[@]}")
proxyapparr=("${rocksworkproxyarr[@]}")
EXTRACT_RESULT_THREADS "ROCKSDB"
#MOVEGRAPHS
exit

export APPPREFIX=""
APP='snappy'
TARGET="$OUTPUTDIR/$APP/$APPPREFIX"
#set the arrays
set_snappy_memimpact_impact_global_vars
apparr=("${snappyworkarr[@]}")
proxyapparr=("${snappyproxyarr[@]}")
let scalefactor=$SCALE_SNAPPY_GRAPH
let APPINTERVAL=100
YTITLE='Throughput (MB/sec) in '$SCALE_SNAPPY_GRAPH'x'
echo $TARGET
XTITLE='Fraction of Memory Capacity Relative to Data Size'

#export GRAPHPYTHON="lineplot.py"
export GRAPHPYTHON="plot.py"
EXTRACT_RESULT_MEMSENSITIVE "snappy"
MOVEGRAPHS-MEMSENSITIVE
exit



export APPPREFIX="20M-KEYS"
APP='ROCKSDB'
TARGET="$OUTPUTDIR/$APP/$APPPREFIX"
#set the arrays
set_rocks_memimpact_impact_global_vars
apparr=("${rocksworkarr[@]}")
proxyapparr=("${rocksworkproxyarr[@]}")
let scalefactor=$SCALE_ROCKSDB_GRAPH
let APPINTERVAL=10
YTITLE='Throughput (OPS/sec) in '$SCALE_ROCKSDB_GRAPH'x'
echo $TARGET
XTITLE='Fraction of Memory Capacity Relative to Database Size'

export GRAPHPYTHON="lineplot.py"
EXTRACT_RESULT_MEMSENSITIVE "ROCKSDB"
MOVEGRAPHS-MEMSENSITIVE
exit

APPPREFIX=""
APP='filebench'
TARGET="$OUTPUTDIR/$APP/workloads"
set_filebench_global_vars
apparr=("${filesworkarr[@]}")     
proxyapparr=("${fileproxyarr[@]}")
let scalefactor=$SCALE_FILEBENCH_GRAPH
let APPINTERVAL=500
YTITLE='Throughput (OPS/sec) in '$SCALE_FILEBENCH_GRAPH'x'
echo $TARGET
XTITLE='Workloads'
EXTRACT_RESULT "filebench"
MOVEGRAPHS
exit











export APPPREFIX="20M-KEYS"
APP='YCSB-ROCKSDB'
TARGET="$OUTPUTDIR/$APP/$APPPREFIX"
#set the arrays
set_rocks_ycsb_global_vars
apparr=("${rocksycsbarr[@]}")
proxyapparr=("${rocksycsbproxyarr[@]}")
let scalefactor=$SCALE_YCSB_GRAPH
let APPINTERVAL=100
YTITLE='Throughput (OPS/sec) in '$SCALE_YCSB_GRAPH'x'
echo $TARGET
XTITLE='Workloads'
EXTRACT_RESULT "YCSB-ROCKSDB"
MOVEGRAPHS
exit







APP='SIMPLEBENCH'
TARGET="$OUTPUTDIR/SIMPLEBENCH"

#set the arrays
set_simplebench_global_vars

let APPINTERVAL=200
YTITLE='Throughput (MB/sec) in 10x'
XTITLE='#. of threads'
echo $TARGET
apparr=("${simplebenchworkarr[@]}")
proxyapparr=("${simplebenchproxyarr[@]}")
EXTRACT_RESULT "SIMPLEBENCH"
MOVEGRAPHS
EXTRACT_RESULT_THREADS "SIMPLEBENCH"
MOVEGRAPHS
exit



APP='snappy'
TARGET="$OUTPUTDIR/snappy"

#set the arrays
set_snappy_global_vars

let APPINTERVAL=2000
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

