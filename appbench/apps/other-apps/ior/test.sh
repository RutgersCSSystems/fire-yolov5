#!/bin/bash
#set -x

REFRESH() {
	$SCRIPTS/compile-install/clear_cache.sh
	sudo sh -c "dmesg --clear" ##clear dmesg
	sleep 2
}

FILENAME=test_outfile_ior
NPROC=8
TRANSFERSZ=8192 #TRANSFER
BLOCKPROD=100000 #blocksize = transfersize*blockprod
NR_SEGMENTS=10 #SEGMENT
PREFETCH_WIN=2 #TPREFETCH

BLOCKSIZE=`echo "$TRANSFERSZ * $BLOCKPROD" | bc`
export TIMESPREFETCH=$PREFETCH_WIN
APPPREFIX="/usr/bin/time -v"

REORDER="-C"
FILEPERPROC="-F"
KEEPFILE="-k"
RANDOMACCESS=" -z"

PARAMS="-e -o $FILENAME -v -b $BLOCKSIZE -t $TRANSFERSZ -s $NR_SEGMENTS $FILEPERPROC $KEEPFILE"
PARAMSREAD="-e -o $FILENAME -v -b $BLOCKSIZE -t $TRANSFERSZ -s $NR_SEGMENTS $FILEPERPROC $RANDOMACCESS $KEEPFILE"

WRITE=" -w "
READ=" -r "

#rm -rf $FILENAME*
#echo "********** prepping File **************"
#$APPPREFIX mpirun -np $NPROC ior $WRITE $PARAMS
REFRESH

#export LD_PRELOAD="/usr/lib/libcrosslayer.so"
export LD_PRELOAD="/usr/lib/libjuststats.so"
#echo "********** read workload *************"
$APPPREFIX mpirun -np $NPROC ior $READ $PARAMSREAD



