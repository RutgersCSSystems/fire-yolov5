#!/bin/bash
sudo dmesg -c
$SHARED_LIBS/construct/reset
stop-dfs.sh  && stop-yarn.sh
rm -rf $HADOOP_HOME/hdfs/*
