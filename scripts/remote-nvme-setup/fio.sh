#!/usr/bin/env bash
set -x
IODEPTH=16
NUMJOBS=4
WORKLOADS="write"
REMOTE_STORAGE="/dev/nvme1n1"


sudo apt-get update && sudo apt-get install fio -y
PARAMS="--rw=randread --iodepth=256 --numjobs=8"
STORAGE=$REMOTE_STORAGE
#STORAGE=$LOCAL_STORAGE


sudo fio --filename=$STORAGE --direct=1 --bs=4k --ioengine=libaio --time_based --group_reporting --name=readlatency-test-job --runtime=120 --eta-newline=1 $PARAMS
set +x
