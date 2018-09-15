#!/bin/bash
echo "   "
APP=graphchi
grep "Elapsed" $OUTPUTDIR/$APP | awk '{print $8}'
APP=db_bench
cat $OUTPUTDIR/$APP | grep "MB/s" | awk 'BEGIN {SUM=0}; {SUM=SUM+$7}; END {print SUM}'
APP=fio
cat $OUTPUTDIR/$APP | grep "bw=" | awk '{print $2}'| grep -o '[0-9]*' | awk '{sum += $1} END {print sum}'
APP=Metis
grep "Real:" $OUTPUTDIR/$APP | awk '{print $2}'
APP=redis
cat $OUTPUTDIR/$APP | grep -a "ET:" | awk 'BEGIN {SUM=0}; {SUM+=$3}; END {printf "%5.3f\n", SUM}'
APP=memcached
cat $OUTPUTDIR/$APP | grep -a "SETS:" | awk 'BEGIN {SUM=0}; {SUM=$2+$4}; END {print SUM}'
echo "________________________"
APP=leveldb
awk 'BEGIN {SUM=0}; {SUM=SUM+$3}; END {printf "%.3f\n", SUM}' $OUTPUTDIR/$APP
