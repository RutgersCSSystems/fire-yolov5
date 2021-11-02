#!/bin/bash

OUTFOLDER="$PWD/zplot-ramdisk-analysis"

DBHOME=$PWD
PREDICT=1
VALUE_SIZE=4096
SYNC=0
KEYSIZE=100
WRITE_BUFF_SIZE=67108864
NUM=1000000
DBDIR=/mnt/ext4ramdisk/DATA
NR_REPEATS=5 ##Number of retrys of the same config

WORKLOADS="readrandom"
APPPREFIX="/usr/bin/time -v"

declare -a setra=("256" "512" "4096" "8192" "16384")
declare -a valuesz=("4" "32" "128" "1024") #4K, 32K, 128K, 1M
declare -a nproc=("16" "32")
declare -a workloads=("readrandom" "readseq")


ResetRocks()
{
       cd $DBDIR
       rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
       cd ..

}

FlushDisk()
{
       sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
       sudo sh -c "sync"
       sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
       sudo sh -c "sync"
}

SETPRELOAD()
{
       if [[ "$PREDICT" == "1" ]]; then
               export LD_PRELOAD=/usr/lib/libcrosslayer.so
       else
               export LD_PRELOAD=/usr/lib/libnopred.so
       fi
}

BUILD_LIB()
{
       pushd $SHARED_LIBS/pred
       ./compile.sh
       popd
}

min_number() {
       printf "%s\n" "$@" | sort -g | head -n1
}

max_number() {
       printf "%s\n" "$@" | sort -gr | head -n1
}

for NPROC in "${nproc[@]}"
do
       RESULTS_FILE=${OUTFOLDER}/22Aug-ior-sensidat-diff_files-${NPROC}-proc.txt

       echo "#RA_SIZE,min-4k,avg-4k,max-4k"\
       ",min-32k,avg-32k,max-32k"\
       ",min-128k,avg-128k,max-128k"\
       ",min-1m,avg-1m,max-1m" > $RESULTS_FILE
       for SETRA in "${setra[@]}"
       do
               sudo blockdev --setra $SETRA $DEV
               echo -n "$SETRA" >> $RESULTS_FILE #start of a new row
               for TXSZ in "${transfersz[@]}"
               do
                       VALUE_SIZE=`echo "$TXSZ*KB" | bc`
                       PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE \
                               --wal_dir=$DBDIR/WAL_LOG \
                               --sync=$SYNC --key_size=$KEYSIZE \
                               --write_buffer_size=$WRITE_BUFF_SIZE \
                               --threads=$THREAD --num=$NUM"

                       WRITEARGS="--benchmarks=fillrandom \
                               --use_existing_db=0 \
                               --threads=$NPROC"

                       READARGS="--benchmarks=$WORKLOADS \
                               --use_existing_db=1 --mmap_read=0"
        
                       for i in $(seq 1 1 $NR_REPEATS)
                       do
                       done
               done
               echo >> $RESULTS_FILE ##new line
       done
done
