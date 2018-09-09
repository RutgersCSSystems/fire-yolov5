#!/bin/bash
#set -x
export TEST_TMPDIR="/mnt/pmemdir"

NUMTHREAD=1
NUMREADTHREADS="--num_read_threads=1"
BENCHMARKS="fillseq,stats"
OTHERPARAMS="--num_levels=2 --write_buffer_size=200 --write_buffer_size_2=5000"

let NUMKEYS=100000
KEYS="--num=$NUMKEYS"
VALSZ="--value_size=4096"


MESSAGE() {
  echo "****************"
  echo "Make sure to set ENABLE_RECOVERY flag and _SIMULATE_FAILURE flag in "
  echo "in build_detect_platform file"  
  echo "****************"
  echo " "
  echo " "
}

SETUP() {
  rm -rf $TEST_TMPDIR/*
  mkdir -p $TEST_TMPDIR
}

MAKE() {
  cd ..
  #make clean
  make -j8
  cd scripts
}

WRITE_EXIT() {
  ../out-static/db_bench --threads=$NUMTHREAD $KEYS --benchmarks=$BENCHMARKS $VALSZ $OTHERPARAMS $NUMREADTHREADS
}

RESTART_READ() {

  BENCHMARKS="readrandom,stats"
  NUMREADTHREADS="--num_read_threads=0"
  NUMKEYS=$((NUMKEYS/10))
  KEYS="--num=$NUMKEYS"
  ../out-static/db_bench --threads=$NUMTHREAD $KEYS --benchmarks=$BENCHMARKS $VALSZ $OTHERPARAMS $NUMREADTHREADS --histogram=1

}

MESSAGE

SETUP
MAKE
WRITE_EXIT
RESTART_READ
#RESTART_READ

