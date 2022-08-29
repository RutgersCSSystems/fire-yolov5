#!/bin/bash

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sleep 5
}


FlushDisk
export LD_PRELOAD="/usr/lib/lib_CII.so"
./bin/read_shared_seq
export LD_PRELOAD=""
