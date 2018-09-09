#!/bin/bash
echo "   "
echo "________________________"
echo "   "
APP=graphchi
grep "Elapsed" $OUTPUTDIR/$APP | awk '{print "Graphchi " $1 " "  $2 " sec"}'
echo "________________________"
APP=redis
echo "   "
echo "REDIS"
echo "   "
grep  -a "SET" $OUTPUTDIR/$APP 
grep  -a "GET" $OUTPUTDIR/$APP
echo "________________________"
APP=Metis
echo "   "
grep "Real:" $OUTPUTDIR/$APP | awk '{print "Metis runtime: "  $2 " msec"}'
echo "________________________"
APP=leveldb
echo "   "
grep "micros/op" $OUTPUTDIR/$APP #| awk '{print $3}'
echo "________________________"
APP=fio
echo "   "
grep "READ: bw=" $OUTPUTDIR/$APP
grep "WRITE: bw=" $OUTPUTDIR/$APP
echo "________________________"

