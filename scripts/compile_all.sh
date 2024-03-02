#!/bin/bash
set -x
#create empty file
touch $BASE/dummy.txt

COMPILEOUT=$BASE/scripts/compile
mkdir $COMPILEOUT


cd $BASE
cd $PREDICT_LIB_DIR
./compile.sh &> $COMPILEOUT/LIB.out

cd $BASE/appbench/apps/rocksdb
./compile.sh &> $COMPILEOUT/rocksdb.out
grep -r "error:" $COMPILEOUT/rocksdb.out


cd $BASE/appbench/apps/snappy-c
./compile.sh &> $COMPILEOUT/snappy.out
grep -r "error:"  $COMPILEOUT/snappy.out

cd $BASE/appbench/apps/RocksDB-YCSB
./compile.sh &> $COMPILEOUT/rocksdb-ycsb.out
grep -r "error:"  $COMPILEOUT/rocksdb-ycsb.out

cd $BASE/appbench/apps/simple_bench/multi_thread_read
./compile.sh &> $COMPILEOUT/multi_thread_read.out
grep -r "error:" $COMPILEOUT/rocksdb-ycsb.out

cd $BASE/appbench/apps/simple_bench/mmap_exp
./compile.sh &> $COMPILEOUT/mmap_exp.out
grep -r "error:" $COMPILEOUT/mmap_exp.out

cd $BASE/appbench/apps/filebench
./compile.sh &> $COMPILEOUT/filebench.out
grep -r "error:" $COMPILEOUT/filebench.out

cd $BASE
exit


