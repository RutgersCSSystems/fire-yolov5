#!/bin/bash
DBHOME=$PWD
PREDICT=0
THREAD=4
VALUE_SIZE=512
SYNC=0
WRITE_BUFF_SIZE=67108864
NUM=10000000
DBDIR=$DBHOME/DATA

WORKLOAD="fileserver.f"
#WORKLOAD="randomread.f"
DATAPATH="workloads/$WORKLOAD"
APPPREFIX="/usr/bin/time -v"

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

CLEAR_PWD()
{
	rm -rf $DBDIR/*
}

RUN()
{
	./filebench -f $DATAPATH #&> $PREDICT"-FILEBENCH-"$WORKLOAD".out"
}

#Run write workload twice
#CLEAR_PWD




echo "RUNNING Crosslayer.................."
FlushDisk
PREDICT="CROSSLAYER"
SETPRELOAD
RUN
FlushDisk
export LD_PRELOAD=""



PREDICT="VANILLA"
echo "RUNNING $PREDICT.................."
FlushDisk
SETPRELOAD
RUN
FlushDisk
export LD_PRELOAD=""
exit



