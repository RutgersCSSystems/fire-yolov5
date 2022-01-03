sudo sh -c "dmesg --clear"

export IOMODE=SYNC
export FILETYPE=UNIQUE
export IOMETHOD=POSIX
#RECORD=16777216 # bytes read at once
RECORD=4194304 # 4Mbytes read at once
#RECORD=1048576 # bytes read at once
STRIDE=7 # set stride to $STRIDE * RECORD_SIZE
NPROC=16 ##Num MPI procs
FLUSH=1 ##flush writes

export FUTUREPREFETCH=10
export TIMESPREFETCH=2

DEV=/dev/sda4
RASIZE=8192 #Pages allowed to readahead (320 = 1280 KB, 512 pages = 2048 KB)

#export LD_PRELOAD="/usr/lib/libcrosslayer.so"
export LD_PRELOAD="/usr/lib/libnopred.so"

sudo blockdev --setra $RASIZE $DEV
echo -n "blockdev getra = "; sudo blockdev --getra $DEV

/usr/bin/time -v mpiexec.mpich -n $NPROC ./MADbench2_io 16384 30 1 8 64 1 1 $RECORD $STRIDE $FLUSH
