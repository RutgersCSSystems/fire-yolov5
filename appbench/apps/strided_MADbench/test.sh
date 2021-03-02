#APPPREFIX="numactl --membind=0"


rm -rf files/
$NVMBASE/scripts/clear_cache.sh
sudo sh -c "dmesg --clear"

export IOMODE=SYNC
export FILETYPE=UNIQUE
export IOMETHOD=POSIX
RECORD=16777216 # bytes read at once
#RECORD=4096 # bytes read at once
#RECORD=1048576 # bytes read at once
STRIDE=7 # set stride to $STRIDE * RECORD_SIZE
NPROC=4 ##Num MPI procs
FLUSH=0 ##flush writes

export LD_PRELOAD="/usr/lib/libcrosslayer.so"
#export LD_PRELOAD="/usr/lib/libnopred.so"

#last two values should multiply to NPROC

#/usr/bin/time -v mpiexec -n $NPROC ./MADbench2_io 8192 30 1 8 64 1 1 $RECORD $STRIDE $FLUSH
TIMESPREFETCH=12 /usr/bin/time -v mpiexec -n $NPROC ./MADbench2_io 8192 30 1 8 64 1 1 $RECORD $STRIDE $FLUSH
#strace ./MADbench2_io 4096 1 1 8 64 1 1 $RECORD $STRIDE 2> mystrace
#strace ./MADbench2_io 4096 1 1 8 64 1 1 $RECORD $STRIDE 2> mystrace
#mpiexec -n $NPROC ./MADbench2_io 400 140 1 8 8 1 1
#$APPPREFIX /usr/bin/time -v mpiexec -n $NPROC ./MADbench2.x 2400 140 1 8 8 4 4

export LD_PRELOAD=
