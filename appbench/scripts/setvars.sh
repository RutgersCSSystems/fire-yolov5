#!/bin/bash
export NOVELSMSRC=$PWD
export NOVELSMSCRIPT=$NOVELSMSRC/scripts
export DBBENCH=$NOVELSMSRC/out-static
export TEST_TMPDIR=/mnt/pmemdir
#DRAM buffer size in MB
export DRAMBUFFSZ=64
#NVM buffer size in MB
export NVMBUFFSZ=4096
export INPUTXML=$NOVELSMSCRIPT/input.xml
#Vanilla LevelDB benchmark
export DBBENCH_VANLILLA=$NOVELSMSRC/leveldb-1.20/out-static
export PARA=40
#Numa binding 
export APP_PREFIX="numactl --membind=0"
#export APP_PREFIX=""
