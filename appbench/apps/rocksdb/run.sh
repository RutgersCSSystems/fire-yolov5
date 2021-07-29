#!/bin/bash
DBHOME=$PWD
PREDICT=1
THREAD=16
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
NUM=100000
DBDIR=$DBHOME/DATA

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
}


rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
   
#/usr/bin/time -v ./db_bench --db=./ --value_size=4096 --benchmarks=fillrandom,readrandom,readseq --wal_dir=./WAL_LOG --sync=0 --key_size=1000 --write_buffer_size=67108864 --use_existing_db=0 --threads=$THREAD --num=100000

#exit

./db_bench --db=$DBDIR --value_size=4096 --benchmarks=fillrandom --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=100 --write_buffer_size=67108864 --use_existing_db=0 --threads=$THREAD --num=100000

if [[ "$PREDICT" == "1" ]]; then
    export LD_PRELOAD=/usr/lib/libcrosslayer.so
else
    export LD_PRELOAD=/usr/lib/libnopred.so
fi

FlushDisk

/usr/bin/time -v ./db_bench --db=$DBDIR --value_size=4096 --benchmarks=readrandom --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=100 --write_buffer_size=67108864 --use_existing_db=1 --threads=$THREAD --num=1000000


export LD_PRELOAD=""
