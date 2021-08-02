#!/bin/bash

# Requires the follow enviroment vartiables to be set:
#  1.APPS

if [ -z "$APPS" ]; then
    echo "APPS environment variable is undefined."
    echo "Did you setvars?"
    exit 1
fi

ROCKSDB_PATH=$APPS/rocksdb

rocksdb_clean () {
    echo "Cleaning RocksDB"
    pushd $ROCKSDB_PATH
    make clean -j
    popd
}

sudo apt-get install -y libgflags2.2 libgflags-dev libsnappy-dev zlib1g-dev libbz2-dev liblz4-dev libzstd-dev

rocksdb_clean

echo "compiling rocksdb"
pushd $ROCKSDB_PATH
make clean
DEBUG_LEVEL=0 make db_bench -j$(nproc)
popd
