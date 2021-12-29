#!/bin/bash
set -x
DBHOME=$PWD
PREDICT="OSONLY"
THREAD=16
SYNC=0
NUM=200000000
DBDIR=$DBHOME/checkpoint

APPNAME="hacc-io"

APPREAD="mpiexec -n $THREAD ./hacc_io_read"
APPGEN="mpiexec -n $THREAD ./hacc_io_write"

PARAMS="$NUM $DBDIR"

mkdir $DBDIR

FlushDisk()
{
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
}

SETPRELOAD()
{
	if [[ "$PREDICT" == "LIBONLY" ]]; then 	
		#uses read_ra but disables OS prediction
		echo "setting LIBONLY pred"
		export LD_PRELOAD=/usr/lib/libonlylibpred.so
	elif [[ "$PREDICT" == "CROSSLAYER" ]]; then
		#uses read_ra
		echo "setting CROSSLAYER pred"
		export LD_PRELOAD=/usr/lib/libos_libpred.so

	elif [[ "$PREDICT" == "OSONLY" ]]; then 	
		#does not use read_ra and disables all application read-ahead
		echo "setting OS pred"
		export LD_PRELOAD=/usr/lib/libonlyospred.so
	else [[ "$PREDICT" == "VANILLA" ]]; #does not use read_ra
		echo "setting VANILLA"
		export LD_PRELOAD=""
	fi

}

BUILD_LIB()
{
	cd $SHARED_LIBS/pred
	./compile.sh
	cd $DBHOME
}

CLEANUP()
{
	rm -rf $DBDIR/*
	sudo killall cachestat
	sudo killall cachestat
}

RUNCACHESTAT()
{
	sudo $HOME/ssd/perf-tools/bin/cachestat &> "CACHESTAT-"$APPNAME"-"$PREDICT".out" &
}

RUNAPP() 
{
	RUNCACHESTAT
	$APPREAD $PARAMS &> $APPNAME"-"$PREDICT".out"
	export LD_PRELOAD=""
	CLEANUP

}

#Run write workload twice
#CLEAR_PWD
$APPGEN $PARAMS


echo "RUNNING BASICS.............."
FlushDisk
#PREDICT="CROSSLAYER"
PREDICT="BASICS"
FlushDisk
#SETPRELOAD
RUNAPP
FlushDisk
exit

echo "RUNNING CROSSLAYER.................."
FlushDisk
PREDICT="CROSSLAYER"
FlushDisk
SETPRELOAD
RUNAPP

FlushDisk

echo "RUNNING OSONLY.................."
PREDICT="OSONLY"
SETPRELOAD
RUNAPP

FlushDisk
echo "RUNNING Vanilla.................."
FlushDisk
PREDICT="VANILLA"
SETPRELOAD
RUNAPP
exit


