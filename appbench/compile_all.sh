#!/bin/bash
set -x
#create empty file
touch $BASE/dummy.txt

cd $BASE
cd $PREDICT_LIB_DIR
./compile.sh &> LIB.out

cd $BASE/appbench/apps/rocksdb
./compile.sh &> rocksdb.out


cd $BASE/appbench/apps/snappy-c
./compile.sh &> snappy.out

cd $BASE/appbench/apps/RocksDB-YCSB
./compile.sh &> rocksdb-ycsb.out

cd $BASE/appbench/apps/simple_bench/multi_thread_read
./compile.sh &> multi_thread_read.out

cd $BASE/appbench/apps/simple_bench/mmap_exp
./compile.sh &> mmap_exp.out

cd $BASE/appbench/apps/filebench
./compile.sh &> filebench.out

cd $BASE
exit


