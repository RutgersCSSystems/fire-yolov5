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
#declare -a workload_arr=("mongo.f")
#declare -a config_arr=("Cross_Info" "Cross_Blind" "OSonly")
declare -a config_arr=("OSonly")
declare -a thread_arr=("16")


echo 0 | sudo tee /proc/sys/kernel/randomize_va_space

cd $PREDICT_LIB_DIR
./compile.sh
cd $DBHOME


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

print_results() {

	echo "Vanilla Results"
	cat $RESULTS/VANILLA.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

	echo "CPNI Results"
	cat $RESULTS/CPNI.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

	echo "CNI Results"
	cat $RESULTS/CNI.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

	echo "CPBI Results"
	cat $RESULTS/CPBI.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

	echo "CPBV Results"
	cat $RESULTS/CPBV.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

	echo "CPNV Results"
	cat $RESULTS/CPNV.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

	echo "CROSS-NAIVE Results"
	cat $RESULTS/Cross_Naive.out | grep "$WORKLOAD" | awk '{print $7}'
	echo "...."

}


GEN_RESULT_PATH() {
	TYPE=$1
	CONFIG=$2
	THREAD=$3
	#WORKLOAD="DUMMY"
	#RESULTFILE=""
        RESULTS=$OUTPUTDIR/$APPOUTPUTNAME/$TYPE/$THREAD
	mkdir -p $RESULTS
	RESULTFILE=$RESULTS/$CONFIG.out
}


RUN() {


	for WORKLOAD in "${workload_arr[@]}"
	do
		for CONFIG in "${config_arr[@]}"
		do
			for THREAD in "${thread_arr[@]}"
			do

				RESULTS=""
				WORKPATH="workloads/$WORKLOAD"
				WRITEARGS="-f $WORKPATH"
				READARGS="-f $WORKPATH"
				#RESULTS=$OUTPUTDIR/$APP/$WORKLOAD
				GEN_RESULT_PATH $WORKPATH $CONFIG $THREAD

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
}

RUN
#print_results
#CLEAR_DATA
exit
