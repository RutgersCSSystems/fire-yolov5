#!/bin/bash
DBHOME=$PWD
PREDICT=1
THREAD=1
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
NUM=100000
DBDIR=$DBHOME/DATA

WRITEARGS="--benchmarks=fillrandom --use_existing_db=0"
READARGS="--benchmarks=readrandom --use_existing_db=1"
APPPREFIX="/usr/bin/time -v"

PARAMS="--db=$DBDIR --value_size=4096 --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=100 --write_buffer_size=67108864 --threads=$THREAD --num=$NUM"

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
}

cd $DBDIR
rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
cd ..

FlushDisk

$DBHOME/db_bench $PARAMS $WRITEARGS


if [[ "$PREDICT" == "1" ]]; then
    export LD_PRELOAD=/usr/lib/libcrosslayer.so
else
    export LD_PRELOAD=/usr/lib/libnopred.so
fi

./db_bench $PARAMS $READARGS


export LD_PRELOAD=""

./db_bench $PARAMS $READARGS

