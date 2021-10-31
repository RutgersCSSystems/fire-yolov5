#!/bin/bash
#set -x
DBHOME=$PWD
PREDICT=1
THREAD=16
VALUE_SIZE=1024
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
NUM=2000000
DBDIR=$DBHOME/DATA

WORKLOADS="readseq"
WRITEARGS="--benchmarks=fillrandom --use_existing_db=0 --threads=1"
READARGS="--benchmarks=$WORKLOADS --use_existing_db=1 --mmap_read=0"
APPPREFIX="/usr/bin/time -v"

PARAMS="--db=$DBDIR --value_size=4096 --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=100 --write_buffer_size=67108864 --threads=$THREAD --num=$NUM --target_file_size_base=4096000000"

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
}

SETPRELOAD()
{
	if [[ "$PREDICT" == "1" ]]; then
	    export LD_PRELOAD=/usr/lib/libcrosslayer.so
	    #export LD_PRELOAD=/usr/lib/shim_common.so
	else
	    export LD_PRELOAD=/usr/lib/libnopred.so
	fi
}

BUILD_LIB()
{
	cd $SHARED_LIBS/pred
	./compile.sh
	cd $DBHOME
}

RUNGRAPHCHI(){
	cd /localhome/sudarsun/projects/HPC/NVM/appbench/apps/graphchi
	./run.sh &
	cd $DBHOME	
}


#cd $DBDIR
rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
cd ..


#Build the predictor library
#BUILD_LIB

#Run write workload twice
$DBHOME/db_bench $PARAMS $WRITEARGS #&> out.txt
#FlushDisk
#FlushDisk

exit


echo "RUNNING VANILLA READSEQ....without Graphchi"
WORKLOADS="readseq,readrandom,readreverse,readwhilewriting"
READARGS="--benchmarks=$WORKLOADS --use_existing_db=1 --mmap_read=0"

SETPRELOAD
$DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk
FlushDisk

echo "----------------------------------------------------------------"
exit


echo "RUNNING VANILLA READSEQ....with Graphchi"
WORKLOADS="readseq,readrandom,readreverse"
READARGS="--benchmarks=$WORKLOADS --use_existing_db=1 --mmap_read=0"
#RUNGRAPHCHI
$DBHOME/db_bench $PARAMS $READARGS
#sudo killall pagerank
FlushDisk
FlushDisk
FlushDisk

exit

echo "----------------------------------------------------------------"

echo "RUNNING CROSSLAYER READSEQ...."
WORKLOADS="readseq,readrandom,readreverse"
READARGS="--benchmarks=$WORKLOADS --use_existing_db=1 --mmap_read=0"
SETPRELOAD
$DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk

#echo "RUNNING CROSSLAYER READRANDOM...."
#WORKLOADS="readrandom"
#READARGS="--benchmarks=$WORKLOADS --use_existing_db=1 --mmap_read=0"
#SETPRELOAD
#$DBHOME/db_bench $PARAMS $READARGS
#export LD_PRELOAD=""
#FlushDisk
#exit 



#echo "RUNNING VANILLA READRANDOM...."
#WORKLOADS="readrandom"
#READARGS="--benchmarks=$WORKLOADS --use_existing_db=1 --mmap_read=0"
#$DBHOME/db_bench $PARAMS $READARGS
FlushDisk




