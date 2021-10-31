#!/bin/bash
DBHOME=$PWD
PREDICT=0
THREAD=4
VALUE_SIZE=512
SYNC=0
KEYSIZE=100
WRITE_BUFF_SIZE=67108864
NUM=10000000
DBDIR=$DBHOME/DATA

WORKLOADS="readrandom"
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
		echo "setting pred"
		export LD_PRELOAD=/usr/lib/libcrosslayer.so
	else
		echo "setting nopred"
		export LD_PRELOAD=/usr/lib/libjuststats.so
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
#CLEAR_PWD
#$DBHOME/db_bench $PARAMS $WRITEARGS &> out.txt

echo "RUNNING Vanilla.................."
FlushDisk
PREDICT=0
SETPRELOAD
./filebench -f workloads/randomread.f
FlushDisk
export LD_PRELOAD=""
exit

CLEAR_PWD
$DBHOME/db_bench $PARAMS $WRITEARGS &> out.txt

FlushDisk
echo "RUNNING Crosslayer.................."
PREDICT=1
SETPRELOAD
strace $DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk
