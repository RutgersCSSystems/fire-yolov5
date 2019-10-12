#!/bin/bash
set -x
APPBASE=$APPBENCH/apps/filebench
APP=$APPBASE/filebench
DATA=$SHARED_DATA
SIZE=" --size=4G"
PARAM=" --directory=$DATA $SIZE"
OUTPUT=$2
mkdir -p $DATA

sudo chown -R $USER $SHARED_DATA

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

FlushDisk()
{
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
	sudo sh -c "sync"
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

RANDOM_MONGO(){
	echo "Running Random Write"
	#export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so
	#LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so $APPPREFIX $APP -f $APPBASE/workloads/mongo.f
	#LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so 
	$APPPREFIX $APP -f workloads/mongo.f
	#$APPPREFIX $APP -f workloads/videoserver.f
	#$APPPREFIX $APP -f workloads/oltp.f
	#$APPPREFIX $APP -f workloads/randomrw.f
	#export LD_PRELOAD=""
}

RANDOM_WRITE(){
echo "Running Random Write"
#$APPPREFIX $APP $APPBASE/examples/fio-rand-write.job --name=randwrite $PARAM
$APPPREFIX $APP $APPBASE/examples/fio-rand-RW.job --name=randwrite $PARAM
}


RANDOM_READ(){
echo "Running Random Read"
#$APPPREFIX $APP $APPBASE/examples/fio-rand-read.job --name=randread $PARAM
$APPPREFIX $APP $APPBASE/examples/fio-seq-RW.job --name=randwrite $PARAM
}


SEQ_WRITE(){
echo "Running Sequential Write"
$APPPREFIX $APP $APPBASE/examples/fio-seq-write.job  --name=seqwrite $PARAM
}

SEQ_READ(){
echo "Running Sequential Read"
$APPPREFIX $APP $APPBASE/examples/fio-seq-read.job --name=seqread $PARAM
}

cd $APPBASE
FlushDisk
RANDOM_MONGO
#RANDOM_WRITE
FlushDisk
#RANDOM_READ
#FlushDisk
#SEQ_WRITE
#FlushDisk
#SEQ_READ
rm $DATA/*
rm -rf fio-seq-RW
rm -rf fio-rand-RW
set +x

