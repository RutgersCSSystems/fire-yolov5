#!/bin/bash

KB=1024
MB=`echo "1024*$KB" | bc`
GB=`echo "1024*$MB" | bc`
PAGE_SZ=`echo "4*$KB" | bc`
BLOCK_SZ=512 #512 bytes

FILENAME="/mnt/ext4ramdisk/ior_test.dat"
DEV="/dev/loop0"
SETRA=256

PREDICT=1
NPROC=32
TOT_FILE_SIZE=`echo "120*$GB" | bc`

NR_READS=200 ##Number of TRANSFERSZ reads by each mpi proc per segment
TRANSFERSZ=`echo "1*$MB" | bc` #4K
BLOCKSIZE=`echo "$NR_READS*$TRANSFERSZ" | bc`
NR_SEGMENTS=`echo "$TOT_FILE_SIZE/($BLOCKSIZE*$NPROC)" | bc`

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
	sudo dmesg --clear
	if [[ "$PREDICT" == "1" ]]; then
		export LD_PRELOAD=/usr/lib/libcrosslayer.so
	else
		export LD_PRELOAD=/usr/lib/libnopred.so
	fi
}

min_number() {
	printf "%s\n" "$@" | sort -g | head -n1
}

max_number() {
	printf "%s\n" "$@" | sort -gr | head -n1
}


#############################################

VERBOSE="-v"
REORDER="-C"
FILEPERPROC="-F"
KEEPFILE="-k"
WRITE=" -w "
READ=" -r "

sudo blockdev --setra $SETRA $DEV

PARAMS="-e -o=$FILENAME -b=$BLOCKSIZE -t=$TRANSFERSZ -s=$NR_SEGMENTS $FILEPERPROC $KEEPFILE"

#####################################################
#rm $FILENAME*
#mpirun -np $NPROC ior $WRITE $PARAMS
#####################################################

FlushDisk
SETPRELOAD
$APPPREFIX mpirun -np $NPROC ior $READ $PARAMS $VERBOSE
export LD_PRELOAD=""
