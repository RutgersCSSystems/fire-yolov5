#!/bin/bash
#set -x

DBHOME=$PWD
THREAD=4
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
NUM=1000000
DBDIR=$DBHOME/DATA
#APPPREFIX="sudo /usr/bin/time -v"
APP="filebench"
APPOUTPUTNAME="filebench"


#WORKLOAD="readseq"
#WORKLOAD="workloads/fileserver.f"
#WORKLOAD="workloads/filemicro_seqread.f"
WORKLOAD="workloads/filemicro_rread.f"
WRITEARGS="-f $WORKLOAD"
READARGS="-f $WORKLOAD"
RESULTS=$OUTPUTDIR/$APP/$WORKLOAD


mkdir -p $RESULTS
declare -a workload_arr=("filemicro_seqread.f" "videoserver.f" "fileserver.f" "randomrw.f" "randomread.f" "filemicro_rread.f")
declare -a workload_arr=("filemicro_seqread.f" "randomread.f"  "fileserver.f")
declare -a workload_arr=("fileserver.f")
#declare -a workload_arr=("oltp.f")
#declare -a workload_arr=("mongo.f")

declare -a config_arr=("Cross_Info" "CIP" "CII")
#declare -a config_arr=("OSonly")
declare -a thread_arr=("16")

workload_arr_in=$1
config_arr_in=$2
thread_arr_in=$3

glob_prefetchsz=1024
glob_prefechthrd=1

declare -a prefech_sz_arr=("4096" "2048" "1024" "512" "256" "32" "64")
declare -a prefech_thrd_arr=("1" "2" "4" "8" "16")

get_global_arr() {

	if [ ! -z "$workload_arr_in" ] 
	then
		if [ ${#workload_arr_in=[@]} -eq 0 ]; then
		    echo "input array in NULL"
		else
		    workload_arr=("${workload_arr_in[@]}")
		fi
	fi

	if [ ! -z "$config_arr_in" ]
	then
		if [ ${#config_arr_in=[@]} -eq 0 ]; then
		    echo "input array in NULL"
		else
		   config_arr=("${config_arr_in[@]}")
		fi
	fi

	if [ ! -z "$thread_arr_in" ]
	then
		if [ ${#thread_arr_in=[@]} -eq 0 ]; then
		    echo "input array in NULL"
		else
		   thread_arr=("${thread_arr_in[@]}")
		fi
	fi

	if [ ! -z "$4" ]
	then
		prefetchsz=$4
	else
		prefetchsz=$glob_prefetchsz
	fi

	if [ ! -z "$5" ]
	then
		prefechthrd=$5
	else
		prefechthrd=$glob_prefechthrd
	fi
}

get_global_arr




echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo dmesg --clear
        sleep 5
}

CLEAR_DATA()
{
	sudo killall $APP
	sudo killall $APP
	sleep 3
	sudo killall $APP
        rm -rf $DBDIR/*
}


CLEAN_AND_WRITE()
{
        export LD_PRELOAD=""
        CLEAR_DATA
        FlushDisk
}

GEN_RESULT_PATH() {
	TYPE=$1
	CONFIG=$2
	THREAD=$3
        RESULTS=$OUTPUTDIR/$APPOUTPUTNAME/$TYPE/$THREAD
	mkdir -p $RESULTS
	RESULTFILE=$RESULTS/$CONFIG"-PREFETCHSZ-$prefetchsz-PREFETTHRD-$prefechthrd".out
}


RUN() {

	for WORKLOAD in "${workload_arr[@]}"
	do
		for CONFIG in "${config_arr[@]}"
		do
			cd $PREDICT_LIB_DIR
			echo "sed -i "/NR_WORKERS=/c\NR_WORKERS=$prefechthrd" compile.sh"
			sed -i "/NR_WORKERS=/c\NR_WORKERS=$prefechthrd" compile.sh
			echo "sed -i "/PREFETCH_SIZE=/c\PREFETCH_SIZE=$prefetchsz" compile.sh"
			sed -i "/PREFETCH_SIZE=/c\PREFETCH_SIZE=$prefetchsz" compile.sh

			./compile.sh
			cd $DBHOME

			for THREAD in "${thread_arr[@]}"
			do
				RESULTS=""
				WORKPATH="workloads/$WORKLOAD"
				WRITEARGS="-f $WORKPATH"
				READARGS="-f $WORKPATH"
				GEN_RESULT_PATH $WORKPATH $CONFIG $THREAD

				echo $RESULTFILE
				mkdir -p $RESULTS
				echo "For Workload $WORKPATH, generating $RESULTFILE"

				#echo "BEGINNING TO WARM UP ......."
				CLEAN_AND_WRITE
				#echo "FINISHING WARM UP ......."
				echo "..................................................."
				echo "RUNNING $CONFIG...................................."
				echo "..................................................."

				echo "$APPPREFIX $APP $PARAMS $READARGS &> $RESULTFILE"

				export LD_PRELOAD=/usr/lib/lib_$CONFIG.so
				$APPPREFIX $APP $PARAMS $READARGS &> $RESULTFILE
				export LD_PRELOAD=""
				sudo dmesg -c &>> $RESULTFILE
				echo ".......FINISHING $CONFIG......................"
				#CLEAR_DATA
			done
		done

	done
}


for glob_prefetchsz in "${prefech_sz_arr[@]}"
do
	for glob_prefechthrd in "${prefech_thrd_arr[@]}"
	do
	        get_global_arr	
		RUN
	done
done

exit
