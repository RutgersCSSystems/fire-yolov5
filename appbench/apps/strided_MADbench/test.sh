#APPPREFIX="numactl --membind=0"


rm -rf /users/shaleen/ssd/NVM/appbench/apps/strided_MADbench/files/
/users/shaleen/ssd/NVM/scripts/compile-install/clear_cache.sh
sudo sh -c "dmesg --clear"

export IOMODE=SYNC
export FILETYPE=UNIQUE
export IOMETHOD=POSIX
#RECORD=16777216 # bytes read at once
#RECORD=4194304 # bytes read at once 4MB read size
RECORD=1048576 # bytes read at once 1MB read size
STRIDE=7 # set stride to $STRIDE * RECORD_SIZE
NPROC=1 ##Num MPI procs
FLUSH=1 ##flush writes
DEV=/dev/sda4
declare -a rasize=("2560" "4096" "8192" "16384") 
RASIZE=8192 #Pages allowed to readahead (320 = 1280 KB, 512 pages = 2048 KB)


export LD_PRELOAD="/usr/lib/libcrosslayer.so"
#export LD_PRELOAD="/usr/lib/libnopred.so"
export FUTUREPREFETCH=10
export TIMESPREFETCH=15

sudo blockdev --setra $RASIZE $DEV
echo -n "blockdev getra = "; sudo blockdev --getra $DEV
/usr/bin/time -v mpiexec.mpich -n $NPROC ./MADbench2_io 16384 5 1 8 64 1 1 $RECORD $STRIDE $FLUSH
export LD_PRELOAD=
