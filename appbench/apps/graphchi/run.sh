#!/bin/bash
set -x
if [ -z "$NVMBASE" ]; then
    echo "NVMBASE environment variable not defined. Have you ran setvars?"
    exit 1
fi


DATA=com-orkut.ungraph.txt
#DATA=com-youtube.ungraph.txt
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

export GRAPHCHI_ROOT=$APPBENCH/apps/graphchi/graphchi-cpp

#cd $APPBENCH/apps/graphchi 
FlushDisk
echo "edgelist" | $APPPREFIX $APP file $INPUT niters 8
set +x
