#!/bin/bash
set -x
sudo dmesg -c
$SHARED_LIBS/construct/reset
cd /users/skannan/ssd/NVM/appbench/apps/spark/spark-bench
stop-dfs.sh  && stop-yarn.sh
rm -rf $SHARED_DATA/hdfs/*
hadoop namenode -format
sleep 2
start-dfs.sh  && start-yarn.sh
sleep 4
$KERN_SRC/tools/perf/perf stat -e dTLB-load-misses,LLC-load-misses,instructions,minor-faults Terasort/bin/gen_data.sh
/usr/bin/time -v $KERN_SRC/tools/perf/perf stat -e dTLB-load-misses,LLC-load-misses,instructions,minor-faults Terasort/bin/run.sh
sleep 2
$SHARED_LIBS/construct/reset

#SVDPlusPlus/bin/gen_data.sh
#/usr/bin/time -v SVDPlusPlus/bin/run.sh
exit


stop-dfs.sh
#LD_PRELOAD=/usr/lib/libmigration.so $APPPREFIX
#cd $APPBENCH/apps/spark/HiBench
#$APPBENCH/apps/spark/HiBench/bin/workloads/micro/terasort/prepare/prepare.sh
#LD_PRELOAD=/usr/lib/libmigration.so 
#$APPPREFIX $APPBENCH/apps/spark/HiBench/bin/workloads/micro/terasort/hadoop/run.sh
#stop-dfs.sh  && stop-yarn.sh
rm -rf $SHARED_DATA/hdfs/*
