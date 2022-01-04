#!/bin/bash
#APPPREFIX="numactl --membind=0"
APPPREFIX="/usr/bin/time -v"
CAPACITY=$1
PREDICT="LIBONLY"
APP="MADBENCH"

#SETUPEXTRAM
#IOMETHOD = POSIX  IOMODE = SYNC  FILETYPE = UNIQUE  REMAP = CUSTOM
export FILETYPE=SHARED
WORKLOAD=2000
NPROC=4
GANG=20
RMOD=4
WMOD=4
FLUSHAFTERWRITES=1
#export IOMODE=SYNC
#export IOMETHOD=POSIX

OUTPUTDIR="$OUTPUT_FOLDER/CACHESTAT/$APP/"
mkdir -p $OUTPUTDIR

FlushDisk()
{
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        sudo sh -c "sync"
        sudo sh -c "sync"
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
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
                export LD_PRELOAD=/usr/lib/libcrosslayer.so
        elif [[ "$PREDICT" == "OSONLY" ]]; then
                #does not use read_ra and disables all application read-ahead
                echo "setting OS pred"
                export LD_PRELOAD=/usr/lib/libonlyospred.so
        else [[ "$PREDICT" == "VANILLA" ]]; #does not use read_ra
                echo "setting VANILLA"
                export LD_PRELOAD=""
        fi
}

RUNCACHESTAT()
{
	$SCRIPTS/helperscripts/cache-stat.sh &> $OUTPUTDIR/CACHESTAT"-"$PREDICT.out
}

KILLCACHESTAT()
{
	sudo killall cachestat

}

RUNEXP() {
	$APPPREFIX mpiexec -n $NPROC ./MADbench2_io $WORKLOAD $GANG 1 8 8 $RMOD $WMOD  $FLUSHAFTERWRITES &> $OUTPUTDIR/$PREDICT".out"
}


RUNCACHESTAT
export PREDICT="CROSSLAYER"
RUNEXP
export LD_PRELOAD=""
KILLCACHESTAT
KILLCACHESTAT
KILLCACHESTAT
FlushDisk
