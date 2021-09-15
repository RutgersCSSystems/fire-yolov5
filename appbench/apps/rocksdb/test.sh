#!/bin/bash
DBHOME=$PWD
THREAD=1
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
NUM=1000000
DBDIR=$DBHOME/DATA

WORKLOADS="readseq"
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
	if [[ "$1" == "1" ]]; then
		echo "setting pred"
		export LD_PRELOAD=/usr/lib/libcrosslayer.so
	else
		echo "setting nopred"
		export LD_PRELOAD=/usr/lib/libnopred.so
	fi
}

BUILD_LIB()
{
	cd $SHARED_LIBS/pred
	./compile.sh
	cd $DBHOME
}

CLEAR_PWD()
{
	cd $DBDIR
	rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
	cd ..
}


#Run write workload twice
CLEAR_PWD
$DBHOME/db_bench $PARAMS $WRITEARGS

echo "RUNNING Vanilla.................."
FlushDisk
SETPRELOAD 0
strace $DBHOME/db_bench $PARAMS $READARGS
FlushDisk
export LD_PRELOAD=""
