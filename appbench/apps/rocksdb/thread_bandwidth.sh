#!/bin/bash

if [ -z "$APPS" ]; then
        echo "APPS environment variable is undefined."
        echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
        exit 1
fi

##This script would run strided MADBench and collect its results
source $RUN_SCRIPTS/generic_funcs.sh

base=$APPS/rocksdb
DBDIR=$base/DATA
SYNC=0 ##Call sync when writing
WRITE_BUFF_SIZE=67108864
VALUESIZE=4096
KEYSIZE=1000
NUM=10000000

declare -a experiment=("VANILLA" "OSONLY" "CN" "CPNV" "CPNI")
declare -a mem_budget=("1")
declare -a threads=("1" "2" "4" "8" "16")

# Memory Budget = total_anon_MB + (total_cache_MB * memory_budget_percent)
# higher means more memory limit
declare -a mem_budget=("1")

WRITEARGS="--benchmarks=fillrandom --use_existing_db=0 --threads=1"
ORI_PARAMS="--db=$DBDIR --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --write_buffer_size=$WRITE_BUFF_SIZE"
ORI_READARGS="--use_existing_db=1 --mmap_read=0"

#updated by lib_memusage
total_anon_MB=0
total_cache_MB=0

WORKLOAD="readrandom"

#Compiles the application
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

CLEAN_AND_WRITE()
{
        printf "in ${FUNCNAME[0]}\n"

        UNSETPRELOAD
        CLEAR_DB
        $base/db_bench $PARAMS $WRITEARGS
        FlushDisk

        ##Condition the DB to get Stable results
        echo "Reading DB Twice to Stabalize results"
        $base/db_bench $PARAMS $ORI_READARGS --benchmarks=readseq --threads=16
        FlushDisk

        SETPRELOAD "MEMUSAGE"
        $base/db_bench $PARAMS $ORI_READARGS --benchmarks=readseq --threads=16 &> out_memusage
        UNSETPRELOAD

        ##update the total anon and cache usage for this app
        total_anon_MB=`cat out_memusage | grep "total_anon_used" | awk '{print $2}'`
        total_cache_MB=`cat out_memusage | grep "total_anon_used" | awk '{print $5}'`

        FlushDisk
}

#Checks if the OUTFILE exists, 
TOUCH_OUTFILE(){
        if [[ ! -e $1 ]]; then
                touch $1
                echo -n "Thread" > $1
                for EXPERIMENT in "${experiment[@]}"
                do
                        echo -n ",$EXPERIMENT" >> $1
                done
                echo >> $1
        else
                echo "$1 Exists!"
        fi
}

#umount_ext4ramdisk


PARAMS="$ORI_PARAMS --value_size=$VALUESIZE --key_size=$KEYSIZE --num=$NUM"

OUTFILENAME="${WORKLOAD}_num-${NUM}_valuesz-${VALUESIZE}_keysz-${KEYSIZE}"
OUTFILE=./$OUTFILENAME
TOUCH_OUTFILE $OUTFILE

#COMPILE_APP
#CLEAN_AND_WRITE

for THREAD in "${threads[@]}"
do
        READARGS="$ORI_READARGS --benchmarks=$WORKLOAD --threads=$THREAD"
        COMMAND="$base/db_bench $PARAMS $READARGS"

        echo -n "$THREAD" >> $OUTFILE

        for EXPERIMENT in "${experiment[@]}"
        do
                FlushDisk
                SETPRELOAD $EXPERIMENT
                $COMMAND &> tmp
                UNSETPRELOAD
                #cat tmp
                this_bw=`cat tmp | grep "$WORKLOAD" | head -1| awk '{print $7}'`
                echo "this bandwidth = "$this_bw
                echo -n ",$this_bw" >> $OUTFILE
        done
        echo >> $OUTFILE
done
