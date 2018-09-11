#!/bin/bash
echo "   "
echo "________________________"
echo "   "
APP=graphchi
grep "Elapsed" $OUTPUTDIR/$APP #| awk '{print "Graphchi " $1 " "  $2 " sec"}'
echo "________________________"
APP=redis
echo "   "
echo "REDIS"
echo "   "
cat $OUTPUTDIR/$APP | grep -a "requests per second" | awk 'BEGIN {SUM=0}; {SUM=SUM+$2}; END {printf "%.3f\n", SUM}'
echo "________________________"
APP=Metis
echo "   "
grep "Real:" $OUTPUTDIR/$APP | awk '{print "Metis runtime: "  $2 " msec"}'
echo "________________________"
APP=leveldb
echo "   "
awk 'BEGIN {SUM=0}; {SUM=SUM+$3}; END {printf "%.3f\n", SUM}' $OUTPUTDIR/$APP
#grep "micros/op" $OUTPUTDIR/$APP #| awk '{print $3}'
echo "________________________"
APP=fio
echo "   "
cat $OUTPUTDIR/$APP | grep "bw=" | awk '{print $2}'| grep -o '[0-9]*' | awk '{sum += $1} END {print sum}'
echo "________________________"

