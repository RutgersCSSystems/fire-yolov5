#!/bin/bash
#set -x

RUNNOW=1
mkdir $OUTPUTDIR

USAGE(){
echo "./app \$maxhotpage \$BW \$outputdir \$app"
}

RUNAPP(){
  rm $OUTPUTDIR/$APP
  export LD_PRELOAD=/usr/lib/libmigration.so
  cd $APPBASE
  $APPBASE/run.sh $RUNNOW $OUTPUTDIR/$APP &> $OUTPUTDIR/$APP
  export LD_PRELOAD=""
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
	exit


	APPBASE=$APPBENCH/graphchi
	APP=graphchi
	echo "running $APP ..."
	RUNAPP
	rm $SHARED_DATA/com-orkut.ungraph.txt.*

	APPBASE=$APPBENCH/apps/fio
	APP=fio
	echo "running $APP ..."
	RUNAPP

	APPBASE=$APPBENCH/leveldb
	APP=leveldb
	echo "running $APP..."
	RUNAPP

	APPBASE=$APPBENCH/apps/memcached_client
	APP=memcached
	echo "running $APP..."
	RUNAPP

	APPBASE=$APPBENCH/redis-3.0.0/src
	APP=redis
	echo "running $APP..."
	RUNAPP

	APPBASE=$APPBENCH/apps/rocksdb/build
	APP=db_bench
	echo "running $APP ..."
	RUNAPP


        exit

	#APPBASE=$APPBENCH/memcached
	#APP=memcached
	#echo "running $APP ..."
	#RUNAPP

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
