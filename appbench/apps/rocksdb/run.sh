#!/bin/bash

PREDICT=0
THREAD=2
VALUE_SIZE=4096
SYNC=0
KEYSIZE=100
WRITE_BUFF_SIZE=67108864
NUM=100000

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
}


rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/

#./db_bench --db=./ --value_size=4096 --benchmarks=fillrandom,readrandom,readseq --wal_dir=./WAL_LOG --sync=0 --key_size=100 --write_buffer_size=67108864 --use_existing_db=0 --threads=$THREAD --num=100000
./db_bench --db=./ --value_size=4096 --benchmarks=fillrandom --wal_dir=./WAL_LOG --sync=0 --key_size=100 --write_buffer_size=67108864 --use_existing_db=0 --threads=$THREAD --num=100000

if [[ "$PREDICT" == "1" ]]; then
    export LD_PRELOAD=/usr/lib/libcrosslayer.so
else
    export LD_PRELOAD=/usr/lib/libnopred.so
fi

FlushDisk

./db_bench --db=./ --value_size=4096 --benchmarks=readseq --wal_dir=./WAL_LOG --sync=0 --key_size=100 --write_buffer_size=67108864 --use_existing_db=1 --threads=$THREAD --num=100000


export LD_PRELOAD=""
