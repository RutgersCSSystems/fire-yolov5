#!/bin/bash
set -x
export TEST_TMPDIR="/mnt/pmemdir"
LEVELDB_HOME=../leveldb_vanilla

SETUP() {
  rm -rf $TEST_TMPDIR/*
  mkdir -p $TEST_TMPDIR
}

MAKE() {
  currd=$PWD
  cd $LEVELDB_HOME
  make clean
  make -j8
  cd $currd
}

SETUP
MAKE

NUMTHREAD=1
BENCHMARKS="fillseq,readrandom,stats"
OTHERPARAMS="--write_buffer_size=209715200"



$LEVELDB_HOME/out-static/db_bench --threads=$NUMTHREAD --num=100000 --benchmarks=$BENCHMARKS --value_size=4096 $OTHERPARAMS $NUMREADTHREADS
SETUP

$LEVELDB_HOME/out-static/db_bench --threads=1 --num=100000  --benchmarks=$BENCHMARKS --value_size=4096 $OTHERPARAMS
SETUP

$LEVELDB_HOME/out-static/db_bench --threads=1 --num=200000  --benchmarks=$BENCHMARKS --value_size=64 $OTHERPARAMS
SETUP

$LEVELDB_HOME/out-static/db_bench --threads=1 --num=300000  --benchmarks=$BENCHMARKS --value_size=512 $OTHERPARAMS
SETUP

$LEVELDB_HOME/out-static/db_bench --threads=1 --num=1000000  --benchmarks=$BENCHMARKS --value_size=1024 $OTHERPARAMS
SETUP

$LEVELDB_HOME/out-static/db_bench --threads=1 --num=4000000  --benchmarks=$BENCHMARKS --value_size=512 $OTHERPARAMS
SETUP

$LEVELDB_HOME/out-static/db_bench --threads=1 --num=16000000  --benchmarks=$BENCHMARKS --value_size=64 $OTHERPARAMS
SETUP
