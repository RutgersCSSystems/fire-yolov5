#!/bin/bash
set -x
DBHOME=$PWD
THREAD=16
VALUE_SIZE=4096
SYNC=0
KEYSIZE=100
WRITE_BUFF_SIZE=67108864
NUM=100000
DBDIR=$DBHOME/DATA
LOAD_TRACE=$HOME/ssd/ycsb-ledger/load_c_5M
RUN_TRACE=$HOME/ssd/ycsb-ledger/run_c_5M

WRITEARGS="--benchmarks=replay --use_existing_db=0 --threads=1"
READARGS="--benchmarks=replay --use_existing_db=1 --mmap_read=0 --threads=$THREAD"
APPPREFIX="/usr/bin/time -v"

#PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --threads=$THREAD"
PARAMS="--db=$DBDIR --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --write_buffer_size=$WRITE_BUFF_SIZE"

FlushDisk()
{
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
}
#deletes all the database files
CLEAR_DB()
{
        pushd $DBDIR
        rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
        popd
}


export trace_file=$LOAD_TRACE

FlushDisk

CLEAR_DB

$DBHOME/db_bench $PARAMS $WRITEARGS --trace_file=$LOAD_TRACE

#$DBHOME/db_bench $PARAMS $READARGS --trace_file=$RUN_TRACE
