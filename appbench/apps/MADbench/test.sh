NPROC=16
#APPPREFIX="numactl --membind=0"

##export LD_PRELOAD=/usr/lib/libmigration.so 
export LD_PRELOAD=/usr/lib/libcfun.so 

export IOMODE=SYNC
export FILETYPE=UNIQUE
export IOMETHOD=POSIX

mpiexec -n $NPROC ./MADbench2_io 2400 140 1 8 8 4 4
#mpiexec -n $NPROC ./MADbench2_io 400 140 1 8 8 1 1
#$APPPREFIX /usr/bin/time -v mpiexec -n $NPROC ./MADbench2.x 2400 140 1 8 8 4 4
