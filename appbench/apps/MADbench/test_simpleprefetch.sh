#!/bin/bash

#APPPREFIX="numactl --membind=0"
PAGESIZE=4096

export IOMODE=SYNC
export FILETYPE=UNIQUE
export IOMETHOD=POSIX

NO_PIX=16384 ##size of matrix 
NO_MAT=20 ##Number of matrices
#Number of pages should be power of 2
RECORD=`echo "8*$PAGESIZE" | bc` # Read 8 Pages at once
STRIDE=7 # set stride to $STRIDE * RECORD_SIZE
NPROC=4 ##Num MPI procs
FLUSH=1 ##flush writes

declare -a no_mat=("5" "10" "15" "20" "25")

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sleep 5
}

CLEAN_AND_WRITE(){
    echo "Creating Files for reading"
    rm -rf $PWD/files/
    /usr/bin/time -v mpiexec.mpich -n $NPROC ./MADbench2_io $NO_PIX $NO_MAT 1 8 64 1 $NPROC $FLUSH
    FlushDisk
}


for NO_MAT in "${no_mat[@]}"
do
    echo "##################### $NO_MAT"
    #CLEAN_AND_WRITE
    #du -h $PWD/files

    echo "@@@MADbench with no prefetcher"
    export LD_PRELOAD="/usr/lib/libsimplenoprefetcher.so"
    /usr/bin/time -v mpiexec.mpich -n $NPROC ./MADbench2_io $NO_PIX $NO_MAT 1 8 64 1 1 0
    export LD_PRELOAD=
    #FlushDisk

    exit

    echo "@@@MADbench with simple prefetcher"
    export LD_PRELOAD="/usr/lib/libsimpleprefetcher.so"
    /usr/bin/time -v mpiexec.mpich -n $NPROC ./MADbench2_io $NO_PIX $NO_MAT 1 8 64 1 1 $FLUSH
    export LD_PRELOAD=
    FlushDisk

    echo "@@@MADbench with PREAD_RA"
    export LD_PRELOAD="/usr/lib/libsimplepreadra.so"
    /usr/bin/time -v mpiexec.mpich -n $NPROC ./MADbench2_io $NO_PIX $NO_MAT 1 8 64 1 1 $FLUSH
    export LD_PRELOAD=
    FlushDisk

    echo "@@@MADbench with FULL simple prefetcher"
    export LD_PRELOAD="/usr/lib/libsmpl_fullprefetcher.so"
    /usr/bin/time -v mpiexec.mpich -n $NPROC ./MADbench2_io $NO_PIX $NO_MAT 1 8 64 1 1 $FLUSH
    export LD_PRELOAD=
    FlushDisk

done
