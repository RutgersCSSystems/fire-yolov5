#!/bin/bash

PCAnonRatio=1.5
#DBGRATIO=1
#DRATIO=100
#BASE_MEM=2758459392
NPROC=36

ProgMem=`echo "74828 * $NPROC * 1024" | bc` #in bytes For size C
TotalMem=`echo "$ProgMem * $PCAnonRatio" | bc`
TotalMem=`echo $TotalMem | perl -nl -MPOSIX -e 'print ceil($_)'`

sudo cgcreate -g memory:npb
echo $TotalMem | sudo tee /sys/fs/cgroup/memory/npb/memory.limit_in_bytes

#sudo echo $DRATIO > /proc/sys/vm/dirty_ratio
#sudo echo $DBGRATIO > /proc/sys/vm/dirty_background_ratio

export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so 

$APPPREFIX  mpirun -NP $NPROC ./bin/bt.C.x.ep_io

#/usr/bin/time -v cgexec -g memory:npb mpirun -NP $NPROC ./bin/bt.C.x.ep_io
rm -rf btio*

export LD_PRELOAD=""

