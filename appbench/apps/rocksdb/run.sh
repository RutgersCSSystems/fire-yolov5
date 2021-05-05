#!/bin/bash

THREAD=2

rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/


./db_bench --db=./ --value_size=4096 --benchmarks=fillrandom,readrandom,readseq --wal_dir=./WAL_LOG --sync=0 --key_size=100 --write_buffer_size=67108864 --use_existing_db=0 --threads=$THREAD --num=100000
