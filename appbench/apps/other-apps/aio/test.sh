#!/bin/bash

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sleep 2
}

rm -rf bigfakefile.txt
./write

FlushDisk
free -h

/usr/bin/time -v ./read_os_aiopfetch

free -h
