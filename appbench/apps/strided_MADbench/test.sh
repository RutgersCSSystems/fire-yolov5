#APPPREFIX="numactl --membind=0"


rm -rf /users/shaleen/ssd/NVM/appbench/apps/strided_MADbench/files/
/users/shaleen/ssd/NVM/scripts/compile-install/clear_cache.sh
sudo sh -c "dmesg --clear"

export IOMODE=SYNC
export FILETYPE=UNIQUE
export IOMETHOD=POSIX
#RECORD=16777216 # bytes read at once
RECORD=4096 # bytes read at once
#RECORD=1048576 # bytes read at once
STRIDE=7 # set stride to $STRIDE * RECORD_SIZE
NPROC=16 ##Num MPI procs
FLUSH=1 ##flush writes

#AMPLXE=/opt/intel/vtune_amplifier_2019/bin64/amplxe-cl
#CONFIG_AMPLXE="-trace-mpi -collect hotspots -k enable-stack-collection=true -k stack-size=0 -k sampling-mode=hw"
#CONFIG_AMPLXE="-trace-mpi -collect io -k kernel-stack=false -k spdk=true"
#CONFIG_AMPLXE="-trace-mpi -collect memory-consumption"
#CONFIG_AMPLXE="-trace-mpi -collect hpc-performance -k enable-stack-collection=true -k stack-size=2147483640 -k collect-affinity=true "
#CONFIG_AMPLXE="-trace-mpi -collect platform-profiler"

#export LD_PRELOAD="/usr/local/lib/libdarshan.so"
#export LD_PRELOAD="/usr/lib/libcrosslayer.so"
export LD_PRELOAD="/usr/lib/libnopred.so"

TIMESPREFETCH=2 /usr/bin/time -v mpiexec -n $NPROC ./MADbench2_io 16384 10 1 8 64 1 1 $RECORD $STRIDE $FLUSH

export LD_PRELOAD=
