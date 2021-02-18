#APPPREFIX="numactl --membind=0"


rm -rf files/
./clear_cache.sh
#dmesg -c

export IOMODE=SYNC
export FILETYPE=UNIQUE
export IOMETHOD=POSIX
RECORD=1048576 # bytes read at once
STRIDE=7 # set stride to $STRIDE * RECORD_SIZE
NPROC=1

#export LD_PRELOAD="/usr/lib/libcrosslayer.so"
#export LD_PRELOAD="/usr/lib/libnopred.so"

#last two values should multiply to NPROC

#/usr/bin/time -v mpiexec -n $NPROC ./MADbench2_io 4096 1 1 8 64 1 1 $RECORD $STRIDE
/usr/bin/time -v mpiexec -n $NPROC ./MADbench2_io 4096 1 1 8 64 1 1 $RECORD $STRIDE
#mpiexec -n $NPROC ./MADbench2_io 400 140 1 8 8 1 1
#$APPPREFIX /usr/bin/time -v mpiexec -n $NPROC ./MADbench2.x 2400 140 1 8 8 4 4

export LD_PRELOAD=
