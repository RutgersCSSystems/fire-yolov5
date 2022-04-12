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
NUM=1000000
THREAD=16

declare -a experiment=("VANILLA" "CN" "CNI" "CPNV" "CPNI")
#declare -a experiment=("VANILLA" "CN" "CPNI")
declare -a sst_size=("64" "128" "512" "1024" "2048")
#declare -a sst_size=("512" "1024" "2048")

WRITEARGS="--benchmarks=fillrandom --use_existing_db=0 --threads=1"
ORI_READARGS="--use_existing_db=1 --mmap_read=0"

WORKLOAD="readseq"

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
        $base/db_bench $PARAMS $ORI_READARGS --benchmarks=readseq --threads=16
        FlushDisk
        $base/db_bench $PARAMS $ORI_READARGS --benchmarks=readseq --threads=16
        FlushDisk
}

#Checks if the OUTFILE exists, 
TOUCH_OUTFILE(){
        if [[ ! -e $1 ]]; then
                touch $1
                echo -n "SSTsize" > $1
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


OUTFILENAME="${WORKLOAD}_num-${NUM}_valuesz-${VALUESIZE}_keysz-${KEYSIZE}_threads-${THREAD}"
OUTFILE=./results/$OUTFILENAME
TOUCH_OUTFILE $OUTFILE

#COMPILE_APP

for SST_SIZE in "${sst_size[@]}"
do
	ORI_PARAMS="--db=$DBDIR --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --write_buffer_size=$WRITE_BUFF_SIZE --target_file_size_base=`echo "$SST_SIZE * $MB" | bc`"
	PARAMS="$ORI_PARAMS --value_size=$VALUESIZE --key_size=$KEYSIZE --num=$NUM"
	CLEAN_AND_WRITE

        READARGS="$ORI_READARGS --benchmarks=$WORKLOAD --threads=$THREAD"
        COMMAND="$base/db_bench $PARAMS $READARGS"

	#echo "$COMMAND"
	#exit

        echo -n "$SST_SIZE" >> $OUTFILE
        for EXPERIMENT in "${experiment[@]}"
        do
                FlushDisk
                SETPRELOAD $EXPERIMENT
                $COMMAND &> tmp
                UNSETPRELOAD
                this_bw=`cat tmp | grep "$WORKLOAD" | head -1| awk '{print $7}'`
                echo "this bandwidth = "$this_bw
                echo -n ",$this_bw" >> $OUTFILE
        done
        echo >> $OUTFILE
done
