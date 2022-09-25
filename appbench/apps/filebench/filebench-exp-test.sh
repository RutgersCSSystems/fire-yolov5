#!/bin/bash
set -x

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

#declare -a config_arr=("Vanilla" "Cross_Naive" "CPBI" "CPNI" "CNI" "CPBV" "CPNV")
#declare -a config_arr=("Cross_Naive" "CPBI" "CPNI" "CNI" "CPBV" "CPNV")

declare -a workload_arr=("filemicro_seqread.f" "videoserver.f" "fileserver.f" "randomrw.f" "randomread.f" "filemicro_rread.f")
declare -a workload_arr=("filemicro_seqread.f" "randomread.f"  "fileserver.f")
declare -a workload_arr=("fileserver.f")
declare -a workload_arr=("oltp.f")
declare -a workload_arr=("mongo.f")



declare -a config_arr=("Cross_Info" "CIP" "OSonly" "Vanilla")
#declare -a config_arr=("CIP" "OSonly")
#declare -a config_arr=("OSonly")
declare -a thread_arr=("16")

declare -a prefech_sz_arr=("4096" "2048" "1024" "512" "256" "32" "64")
declare -a prefech_thrd_arr=("1" "2" "4" "8" "16")


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
        #printf "in ${FUNCNAME[0]}\n"
        export LD_PRELOAD=""
        CLEAR_DATA
        FlushDisk
}

GEN_RESULT_PATH() {
	TYPE=$1
	CONFIG=$2
	THREAD=$3
	PREFETCHSZ=$4
	PREFETCHTH=$5
	#WORKLOAD="DUMMY"
	#RESULTFILE=""
        RESULTS=$OUTPUTDIR/$APPOUTPUTNAME/$TYPE/$THREAD
	mkdir -p $RESULTS
	RESULTFILE=$RESULTS/$CONFIG"-PREFETCHSZ-$PREFETCHSZ-PREFETTHRD-$PREFETCHTH".out
}


RUN() {

	for WORKLOAD in "${workload_arr[@]}"
	do
		for CONFIG in "${config_arr[@]}"
		do
			for prefetchsz in "${prefech_sz_arr[@]}"
			do
				for prefechthrd in "${prefech_thrd_arr[@]}"
				do
					cd $PREDICT_LIB_DIR
					sed -i "/NR_WORKERS=/c\NR_WORKERS=$prefechthrd" compile.sh
					sed -i "/PREFETCH_SIZE=/c\PREFETCH_SIZE=$prefetchsz" compile.sh

					./compile.sh
					cd $DBHOME

					for THREAD in "${thread_arr[@]}"
					do
						RESULTS=""
						WORKPATH="workloads/$WORKLOAD"
						WRITEARGS="-f $WORKPATH"
						READARGS="-f $WORKPATH"
						#RESULTS=$OUTPUTDIR/$APP/$WORKLOAD
						GEN_RESULT_PATH $WORKPATH $CONFIG $THREAD $prefetchsz $prefechthrd

						echo $RESULTS/$CONFIG.out

						mkdir -p $RESULTS

						echo "For Workload $WORKPATH, generating $RESULTS/$CONFIG.out"

						#echo "BEGINNING TO WARM UP ......."
						CLEAN_AND_WRITE
						#echo "FINISHING WARM UP ......."
						echo "..................................................."
						echo "RUNNING $CONFIG...................................."
						echo "..................................................."
						export LD_PRELOAD=/usr/lib/lib_$CONFIG.so
						$APPPREFIX $APP $PARAMS $READARGS &> $RESULTS/$CONFIG.out
						export LD_PRELOAD=""
						sudo dmesg -c &>> $RESULTS/$CONFIG.out
						echo ".......FINISHING $CONFIG......................"
						#CLEAR_DATA
					done
				done
			done
		done

	done
}

RUN
#print_results
#CLEAR_DATA
exit
