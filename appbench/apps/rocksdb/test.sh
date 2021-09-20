#!/bin/bash
DBHOME=$PWD
THREAD=1
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
NUM=100000
DBDIR=$DBHOME/DATA

WORKLOAD="readseq"
WRITEARGS="--benchmarks=fillrandom --use_existing_db=0 --threads=1"
READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD"
APPPREFIX="/usr/bin/time -v"

PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --num=$NUM"

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
     elif [[ "$1" == "0" ]]; then
		echo "setting nopred"
		export LD_PRELOAD=/usr/lib/libnopred.so
      else
          echo "only app pred"
		export LD_PRELOAD=/usr/lib/libonlyapppred.so
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
$DBHOME/db_bench $PARAMS $WRITEARGS > /dev/null

echo "RUNNING Only App Pred.................."
FlushDisk
SETPRELOAD -1
$DBHOME/db_bench $PARAMS $READARGS
#/users/shaleen/ssd/ltrace/ltrace -w 5 -rfSC -l /usr/lib/libnopred.so $DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk



#Run write workload twice
CLEAR_PWD
$DBHOME/db_bench $PARAMS $WRITEARGS > /dev/null

echo "RUNNING No Pred.................."
FlushDisk
SETPRELOAD 0
$DBHOME/db_bench $PARAMS $READARGS
#/users/shaleen/ssd/ltrace/ltrace -w 5 -rfSC -l /usr/lib/libnopred.so $DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk
