#!/bin/bash

if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

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
NPROC=64 ##Num MPI procs
FLUSH=1 ##flush writes

ENV="-env MV2_SMP_USE_CMA=0 -env MV2_USE_RoCE=1"

#declare -a no_mat=("5" "10" "15" "20" "25")
declare -a no_mat=("25")

declare -a hosts=("shaleen@ms0841.utah.cloudlab.us" "shaleen@ms0818.utah.cloudlab.us" "shaleen@ms0801.utah.cloudlab.us" "shaleen@ms1202.utah.cloudlab.us")

FlushDisk()
{
	for host in "${hosts[@]}"
	do
		echo "$host flushdisk"
		ssh $host "sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'"
		ssh $host "sudo sh -c 'sync'"
	done
    #sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    #sudo sh -c "sync"
    sleep 5
}

CLEAN()
{
	fileloc=$PWD/files
	for host in "${hosts[@]}"
	do
		echo "$host removing file"
		ssh $host "rm -rf $fileloc"
	done
}


CLEAN_AND_WRITE(){
    echo "Creating Files for reading"

    #rm -rf $PWD/files/
    CLEAN

    #/usr/bin/time -v mpiexec.mpich -n $NPROC ./MADbench2_io $NO_PIX $NO_MAT 1 8 64 1 $NPROC $FLUSH
    #mpirun -env MV2_SMP_USE_CMA=0 -env MV2_USE_RoCE=1 --hostfile ~/hostfile -np $NPROC ./MADbench2_io $NO_PIX $NO_MAT 1 8 64 1 $NPROC $FLUSH

    mpirun -hostfile ~/hostfile $ENV -np $NPROC ./MADbench2_io $NO_PIX $NO_MAT 1 8 64 1 $NPROC $FLUSH > /dev/null
    #mpirun -env MV2_SMP_USE_CMA=0 -env MV2_USE_RoCE=1 -np $NPROC ./MADbench2_io $NO_PIX $NO_MAT 1 8 64 1 $NPROC $FLUSH

    FlushDisk
}


for NO_MAT in "${no_mat[@]}"
do

    COMMAND="$PWD/MADbench2_io $NO_PIX $NO_MAT 1 8 64 1 1 0"

    echo "##################### $NO_MAT"
    CLEAN_AND_WRITE
    du -h $PWD/files
    FlushDisk

    echo "@@@@@@VANILLA"
    mpirun -hostfile ~/hostfile $ENV -np $NPROC $COMMAND |& grep "Bandwidth" | head -1 | awk '{print $3}'
    FlushDisk

    echo "@@@@@@@Cross_FileRA_NoPred_MaxMem_BG"
    mpirun -hostfile ~/hostfile -env LD_PRELOAD=/usr/lib/lib_CFNMB.so $ENV -np $NPROC $COMMAND |& grep "Bandwidth" | head -1 | awk '{print $3}'
    FlushDisk

    echo "@@@@@@@Cross_BlockRA_NoPred_MaxMem_BG"
    mpirun -hostfile ~/hostfile -env LD_PRELOAD=/usr/lib/lib_CBNMB.so $ENV -np $NPROC $COMMAND |& grep "Bandwidth" | head -1 | awk '{print $3}'
    FlushDisk

    echo "@@@@@@@Cross_FileRA_Pred_MaxMem_BG"
    mpirun -hostfile ~/hostfile -env LD_PRELOAD=/usr/lib/lib_CFPMB.so $ENV -np $NPROC $COMMAND |& grep "Bandwidth" | head -1 | awk '{print $3}'
    FlushDisk

    echo "@@@@@@@Cross_BlockRA_Pred_MaxMem_BG"
    mpirun -hostfile ~/hostfile -env LD_PRELOAD=/usr/lib/lib_CBPMB.so $ENV -np $NPROC $COMMAND |& grep "Bandwidth" | head -1 | awk '{print $3}'
    FlushDisk

    echo "@@@@@@@Cross_BlockRA_Pred_Budget_BG_info"
    mpirun -hostfile ~/hostfile -env LD_PRELOAD=/usr/lib/lib_CBPBB_info.so $ENV -np $NPROC $COMMAND |& grep "Bandwidth" | head -1 | awk '{print $3}'
    FlushDisk

done
