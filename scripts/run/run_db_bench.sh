#!/bin/bash
set -x

if [ -z "$APPS" ]; then
    echo "APPS environment variable is undefined."
    echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
    exit 1
fi

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

base=$APPS/rocksdb
DBDIR=$base/DATA

nproc=$1 #nr of mpi procs
experiment=$2 #experiment type
out_base=$3 #base output folder


SYNC=0 ##Call sync when writing 
WRITE_BUFF_SIZE=67108864

declare -a value_size_arr=("4096")
declare -a key_size_arr=("100")
declare -a num_arr=("2000000") ## Num of elements in DB
#declare -a workload_arr=("readseq" "readrandom" "readreverse" "multireadrandom" "readwhilewriting" "readwhilemerging" "readwhilescanning" "readrandomwriterandom" "updaterandom" "xorupdaterandom" "approximatesizerandom" "randomwithverify") ##kinds of db_bench workloads
declare -a workload_arr=("readseq" "readreverse") ##kinds of db_bench workloads


#PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --num=$NUM"
ORI_PARAMS="--db=$DBDIR --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --write_buffer_size=$WRITE_BUFF_SIZE"
WRITEARGS="--benchmarks=fillrandom --use_existing_db=0 --threads=1"
#READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0 --threads=$THREAD"
ORI_READARGS="--use_existing_db=1 --mmap_read=0"

##set based on the current parameters to rocksdb
PARAMS=""
READARGS=""
OUTFOLDER=""
OUTFILE="" 

##TODO:check if the app is already compiled
COMPILE_APP() {
    pushd $base
    ./compile.sh
    popd
}


#deletes all the database files
CLEAR_DB()
{
    pushd $DBDIR
    rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
    popd
}




UNSETPRELOAD() {
	export LD_PRELOAD=""
}



WRITELOAD() {
    CLEAR_DB
    $base/db_bench $PARAMS $WRITEARGS

    $base/db_bench $PARAMS $ORI_READARGS --benchmarks=readseq --threads=16
}

#Checks if the folder exits, if not, create new
CREATE_OUTFOLDER() {
    if [[ ! -e $1 ]]; then
        mkdir -p $1
    else
        echo "$1 already exists"
    fi
}


SETPRELOAD_ROCKSDB()
{
        if [[ "$PREDICT" == "LIBONLY" ]]; then
                #uses read_ra but disables OS prediction
                echo "setting LIBONLY pred"
                cp $base/build_tools/build_detect_platform_cross $base/build_tools/build_detect_platform
                $base/compile.sh &> compile.out
                export LD_PRELOAD=/usr/lib/libonlylibpred.so
        elif [[ "$PREDICT" == "CROSSLAYER" ]]; then
                #uses read_ra
                echo "setting CROSSLAYER pred"
                cp $base/build_tools/build_detect_platform_cross $base/build_tools/build_detect_platform
                $base/compile.sh &> compile.out
                export LD_PRELOAD=/usr/lib/libos_libpred.so
        elif [[ "$PREDICT" == "OSONLY" ]]; then
                #does not use read_ra and disables all application read-ahead
                echo "setting OS pred"
                cp $base/build_tools/build_detect_platform_orig $base/build_tools/build_detect_platform
                $base/compile.sh &> compile.out
                export LD_PRELOAD=/usr/lib/libonlyospred.so
        else [[ "$PREDICT" == "VANILLA" ]]; #does not use read_ra
                echo "setting VANILLA"
                cp $base/build_tools/build_detect_platform_orig $base/build_tools/build_detect_platform
                $base/compile.sh &> compile.out
                export LD_PRELOAD=""
        fi
}


RUNAPP()
{
    COMMAND="$APPPREFIX $base/db_bench $PARAMS $READARGS"

    if [ "$experiment" = "CACHESTAT" ]; then
        sudo dmesg -c


	echo "RUNNING VANILLA"

	TYPE="VANILLA"
        SETPRELOAD_ROCKSDB $TYPE
        $COMMAND &>> $OUTFILE$TYPE
        UNSETPRELOAD
	FlushDisk
	FlushDisk

	TYPE="OSONLY"
        SETPRELOAD_ROCKSDB $TYPE
        $COMMAND &>> $OUTFILE$TYPE
        UNSETPRELOAD
	FlushDisk
	FlushDisk

	TYPE="CROSSLAYER"
        SETPRELOAD_ROCKSDB $TYPE
        $COMMAND &>> $OUTFILE$TYPE
        UNSETPRELOAD
	FlushDisk
	FlushDisk

        dmesg >> $OUTFILE
    fi
}


#COMPILE_APP ##Do this if its not already compiled

for NUM in "${num_arr[@]}"
do
    for VALUESIZE in "${value_size_arr[@]}"
    do
        for KEYSIZE in "${key_size_arr[@]}"
        do
            PARAMS="$ORI_PARAMS --value_size=$VALUESIZE --key_size=$KEYSIZE --num=$NUM"

            for WORKLOAD in "${workload_arr[@]}"
            do
                READARGS="$ORI_READARGS --benchmarks=$WORKLOAD --threads=$nproc"
                OUTFOLDER=$out_base/$WORKLOAD
                CREATE_OUTFOLDER $OUTFOLDER
                OUTFILE=$OUTFOLDER/"valuesize-${VALUESIZE}_keysize-${KEYSIZE}_num-${NUM}--"

                WRITELOAD ##Needs to be called for diff load config
                REFRESH
                RUNAPP 
            done
        done
    done
done
