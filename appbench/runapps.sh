#!/bin/bash
#set -x

RUNNOW=1
RUNSCRIPT=run.sh
mkdir $OUTPUTDIR

USAGE(){
echo "./app \$maxhotpage \$BW \$outputdir \$app"
}

RUNAPP(){
  rm $OUTPUTDIR/$APP
  cd $APPBASE
  $APPBASE/$RUNSCRIPT $RUNNOW $OUTPUTDIR/$APP &> $OUTPUTDIR/$APP
}

intexit() {
    # Kill all subprocesses (all processes in the current process group)
    kill -HUP -$$
}

hupexit() {
    # HUP'd (probably by intexit)
    echo
    echo "Interrupted"
    exit
}

trap hupexit HUP
trap intexit INT

#if [ -z "$1" ]
# then	
#  USAGE 
#  exit
#fi



if [ -z "$4" ]
  then

	APPBASE=$APPBENCH/Metis
	APP=Metis
	echo "running $APP..."
	RUNAPP

	APPBASE=$APPBENCH/apps/fio
	APP=fio
	echo "running $APP ..."
	RUNAPP

	RUNSCRIPT="runfcreate.sh"
        APP=fcreate
        echo "running $APP ..."
        RUNAPP
        RUNSCRIPT=run.sh


	APPBASE=$APPBENCH/redis-3.0.0/src
	APP=redis
	echo "running $APP..."
	RUNAPP


	APPBASE=$APPBENCH/apps/rocksdb/build
	APP=db_bench
	echo "running $APP ..."
	RUNAPP

	APPBASE=$APPBENCH/graphchi
	APP=graphchi
	echo "running $APP ..."
	RUNAPP
	rm $SHARED_DATA/com-orkut.ungraph.txt.*

	APPBASE=$APPBENCH/apps/memcached_client
	APP=memcached
	echo "running $APP..."
	RUNAPP
	export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so
	/bin/ls
	export LD_PRELOAD=""

	#APPBASE=$APPBENCH/memcached/memtier_benchmark
	#APP=memcached
	#echo "running $APP ..."
	#RUNAPP

	exit

	APPBASE=$APPBENCH/apps/mongo-perf
	APP=mongodb
	echo "running $APP..."
	RUNAPP


	APPBASE=$APPBENCH/xstream_release
	APP=xstream_release
	scp -r $HOSTIP:$SHARED_DATA*.ini $APPBASE
        cp $APPBASE/*.ini $SHARED_DATA
	echo "running $APP ..."
	RUNAPP

fi
	
#APPBASE=$APPBENCH/$4
#APP=$4
#RUNAPP
set +x
