#!/bin/bash
set -x
#create empty file
touch $BASE/dummy.txt

EXEC=$BASE/scripts/exec
mkdir $EXEC


cd $BASE
cd $PREDICT_LIB_DIR
./compile.sh &> $EXEC/LIB.out


RUN_SNAPPY() {
	cd $BASE/appbench/apps/snappy-c
	./gendata-run-med.sh 1 &> $EXEC/snappy.out
	./release-run-med.sh &>> $EXEC/snappy.out
	python3 release-extract-med.py &>> $EXEC/snappy.out
}

RUN_RocksDB-YCSB() {
	cd $BASE/appbench/apps/RocksDB-YCSB
	./release-run-med.sh &>> $EXEC/rocksdb-ycsb.out
	python3 release-extract-med.py &>> $EXEC/rocksdb-ycsb.out
}

RUN_RocksDB() {
	cd $BASE/appbench/apps/rocksdb
	./gendata-run-med.sh &> $EXEC/rocksdb.out
	./release-run-med.sh &>> $EXEC/rocksdb.out
	python3 release-extract-med.py &>> $EXEC/rocksdb-ycsb.out
}



RUN_SNAPPY
sleep 10
RUN_RocksDB-YCSB
exit

cd $BASE/appbench/apps/rocksdb
./compile.sh &> $EXEC/rocksdb.out



cd $BASE/appbench/apps/simple_bench/multi_thread_read
./compile.sh &> $EXEC/multi_thread_read.out

cd $BASE/appbench/apps/simple_bench/mmap_exp
./compile.sh &> $EXEC/mmap_exp.out

cd $BASE/appbench/apps/filebench
./compile.sh &> $EXEC/filebench.out

cd $BASE
exit


