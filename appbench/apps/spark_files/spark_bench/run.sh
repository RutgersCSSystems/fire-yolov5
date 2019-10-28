#!/bin/bash
sudo dmesg -c
$SHARED_LIBS/construct/reset
stop-dfs.sh  #&& stop-yarn.sh
rm -rf $HADOOP_HOME/hdfs/*
hadoop namenode -format
sleep 2
start-dfs.sh  #&& start-yarn.sh
Terasort/bin/gen_data.sh
Terasort/bin/run.sh
stop-dfs.sh
#LD_PRELOAD=/usr/lib/libmigration.so $APPPREFIX
#cd $APPBENCH/apps/spark/HiBench
#$APPBENCH/apps/spark/HiBench/bin/workloads/micro/terasort/prepare/prepare.sh
#LD_PRELOAD=/usr/lib/libmigration.so 
#$APPPREFIX $APPBENCH/apps/spark/HiBench/bin/workloads/micro/terasort/hadoop/run.sh
#stop-dfs.sh  && stop-yarn.sh
$SHARED_LIBS/construct/reset
rm -rf $HADOOP_HOME/hdfs/*
