#!/bin/bash
#set -x

RUNNOW=1
mkdir $OUTPUTDIR
rm $OUTPUTDIR/*

USAGE(){
echo "./app \$maxhotpage \$BW \$outputdir \$app"
}

RUNAPP(){
  export LD_PRELOAD=/usr/lib/libmigration.so
  cd $APPBASE
  $APPBASE/run.sh $RUNNOW $OUTPUTDIR/$APP &> $OUTPUTDIR/$APP
  export LD_PRELOAD=""
}


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

	APPBASE=$APPBENCH/graphchi
	APP=graphchi
	echo "running $APP ..."
	RUNAPP
	/bin/rm -rf com-orkut.ungraph.txt.*

	APPBASE=$APPBENCH/redis-3.0.0/src
	APP=redis
	echo "running $APP..."
	RUNAPP

	APPBASE=$APPBENCH/leveldb
	APP=leveldb
	echo "running $APP..."
	RUNAPP

	APPBASE=$APPBENCH/apps/fio
	APP=fio
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