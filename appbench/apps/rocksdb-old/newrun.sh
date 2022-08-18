#!/bin/bash
DBHOME=$PWD
PREDICT=1
THREAD=8
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
NUM=1000000
DBDIR=$DBHOME/DATA

WORKLOADS="readrandom"
WRITEARGS="--benchmarks=fillrandom --use_existing_db=0 --threads=1"
READARGS="--benchmarks=$WORKLOADS --use_existing_db=1 --mmap_read=0"
APPPREFIX="/usr/bin/time -v"

PARAMS="--db=$DBDIR --value_size=4096 --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=100 --write_buffer_size=67108864 --threads=$THREAD --num=$NUM"

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


cd $DBDIR
rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
cd ..


#Build the predictor library
BUILD_LIB

#Run write workload twice
$DBHOME/db_bench $PARAMS $WRITEARGS &> out.txt
FlushDisk


echo "RUNNING CROSSLAYER READSEQ...."
WORKLOADS="readseq"
READARGS="--benchmarks=$WORKLOADS --use_existing_db=1 --mmap_read=0"
SETPRELOAD
$DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk

echo "RUNNING CROSSLAYER READRANDOM...."
WORKLOADS="readrandom"
READARGS="--benchmarks=$WORKLOADS --use_existing_db=1 --mmap_read=0"
SETPRELOAD
$DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk


echo "RUNNING VANILLA READSEQ...."
WORKLOADS="readseq"
READARGS="--benchmarks=$WORKLOADS --use_existing_db=1 --mmap_read=0"
$DBHOME/db_bench $PARAMS $READARGS
FlushDisk

echo "RUNNING VANILLA READRANDOM...."
WORKLOADS="readrandom"
READARGS="--benchmarks=$WORKLOADS --use_existing_db=1 --mmap_read=0"
$DBHOME/db_bench $PARAMS $READARGS
FlushDisk

