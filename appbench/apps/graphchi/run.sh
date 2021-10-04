#!/bin/bash
set -x
if [ -z "$NVMBASE" ]; then
    echo "NVMBASE environment variable not defined. Have you ran setvars?"
    exit 1
fi



PREDICT=0
DATA=com-orkut.ungraph.txt
#DATA=com-friendster.ungraph.txt
INPUT=$SHARED_DATA/$DATA
APPBASE=$APPBENCH/apps/graphchi/graphchi-cpp/bin/example_apps
APP=$APPBASE/pagerank
APPPREFIX="/usr/bin/time -v"

FlushDisk()
{
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
	sudo sh -c "sync"
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}

SETPRELOAD()
{
	if [[ "$PREDICT" == "1" ]]; then
	    export LD_PRELOAD=/usr/lib/libcrosslayer.so
	else
	    export LD_PRELOAD=/usr/lib/libnopred.so
	fi
}

BUILD_LIB()
{
	cd $SHARED_LIBS/pred
	./compile.sh
	cd $DBHOME
}


export GRAPHCHI_ROOT=$APPBENCH/apps/graphchi/graphchi-cpp

#cd $APPBENCH/apps/graphchi 
FlushDisk

echo "RUNNING CROSSLAYER.................."
#$DBHOME/db_bench $PARAMS $WRITEARGS &> out.txt
FlushDisk
FlushDisk
rm -rf $SHARED_DATA/$DATA.*
#SETPRELOAD
echo "edgelist" | $APPPREFIX $APP file $INPUT niters 1
export LD_PRELOAD=""

set +x
