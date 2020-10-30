NPROC=16
#APPPREFIX="numactl --membind=0"


rm -rf files/
./clear_cache.sh
dmesg -c

#export LD_PRELOAD=/usr/lib/libmigration.so
#export LD_PRELOAD="/usr/lib/libcfun.so:/usr/lib/libmigration.so"
export LD_PRELOAD="/usr/lib/libcfun.so"

export IOMODE=SYNC
export FILETYPE=UNIQUE
export IOMETHOD=POSIX

/usr/bin/time -v mpiexec -n $NPROC ./MADbench2_io 1400 140 1 8 8 4 4
#mpiexec -n $NPROC ./MADbench2_io 400 140 1 8 8 1 1
#$APPPREFIX /usr/bin/time -v mpiexec -n $NPROC ./MADbench2.x 2400 140 1 8 8 4 4
