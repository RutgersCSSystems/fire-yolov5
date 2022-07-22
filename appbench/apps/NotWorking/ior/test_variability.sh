#!/bin/bash

KB=1024
MB=`echo "1024*$KB" | bc`
GB=`echo "1024*$MB" | bc`
PAGE_SZ=`echo "4*$KB" | bc`
BLOCK_SZ=512 #512 bytes

FILENAME="/mnt/ext4ramdisk/ior_test.dat"
OUTFOLDER="$PWD/ramdisk-analysis"
mkdir $OUTFOLDER

APP="IOR"
PREDICT=0
NPROC=1
NR_REPEATS=3

NR_READS=200 ##Number of TRANSFERSZ reads by each mpi proc per segment
TRANSFERSZ=`echo "4*$KB" | bc` #4K
BLOCKSIZE=`echo "$NR_READS*$TRANSFERSZ" | bc`
TOT_FILE_SIZE=`echo "30*$GB" | bc` #30GB
NR_SEGMENTS=0
echo "TotalFile size" $TOT_FILE_SIZE
echo "BLOCKSIZE = " $BLOCKSIZE
DEV="/dev/loop0"
TODAY=`date +'%d-%B'` ##todays date

declare -a setra=("256" "512" "1024" "2048" "4096" "8192" "16384")
declare -a nproc=("16" "32")
#declare -a transfersz=("4096" "32768" "131072" "1048576") #4K, 32K, 128K, 1M
declare -a transfersz=("4" "32" "128" "1024") #4K, 32K, 128K, 1M
#declare -a transfersz=("4") #4K, 32K, 128K, 1M
declare -a totsize=("30") #in GB

#declare -a transfersizearr=("4096") #transfer size
#declare -a blockprodarr=("1024") #blocksize = transfersize*blockprod
#declare -a segmentarr=("2048") #segmentsize
APPPREFIX="/usr/bin/time -v"


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


#############################################
#BUILD_LIB

VERBOSE="-v"
REORDER="-C"
FILEPERPROC="-F"
KEEPFILE="-k"
WRITE=" -w "
READ=" -r "


for NPROC in "${nproc[@]}"
do
    RESULTS_FILE=${OUTFOLDER}/$TODAY-$APP-seqread-diff-file-${NPROC}-proc.txt
    echo "RASIZE,4K-min,4K,4K-max,32K-min,32K,32K-max,128K-min,128K,128K-max,1M-min,1M,1M-max" > $RESULTS_FILE
    for SETRA in "${setra[@]}" #For each setra size
    do
        SETRA_PAGES=`echo "($SETRA*$BLOCK_SZ)/$PAGE_SZ" | bc`
        echo -n "$SETRA_PAGES" >> $RESULTS_FILE

        sudo blockdev --setra $SETRA $DEV
        for TXSZ in "${transfersz[@]}" ##For each read size
        do
            TRANSFERSZ=`echo "$TXSZ*$KB" | bc`
            BLOCKSIZE=`echo "$NR_READS*$TRANSFERSZ" | bc`
            NR_SEGMENTS=`echo "$TOT_FILE_SIZE/($BLOCKSIZE*$NPROC)" | bc`

            PARAMS="-e -o=$FILENAME -b=$BLOCKSIZE -t=$TRANSFERSZ -s=$NR_SEGMENTS $FILEPERPROC $KEEPFILE"

            #####################################################
            rm $FILENAME*
            mpirun -np $NPROC ior $WRITE $PARAMS
            #####################################################
            
            min_bw=100000000
            max_bw=0
            avg_bw=0
            this_bw=0
            for NR in $(seq 1 1 $NR_REPEATS)
            do
                FlushDisk
                this_bw=`$APPPREFIX mpirun -np $NPROC ior $READ $PARAMS $VERBOSE | grep "Max Read" | awk '{print $3}'`

                ##########################
                min_bw=$(min_number $this_bw $min_bw)
                max_bw=$(max_number $this_bw $max_bw)
                avg_bw=`echo "scale=2; $avg_bw + $this_bw" | bc -l`
                ##########################

            done
            avg_bw=`echo "scale=2; $avg_bw/$NR_REPEATS" | bc -l`
            echo -n ",$min_bw,$avg_bw,$max_bw" >> $RESULTS_FILE
        done
        echo >> $RESULTS_FILE
    done
done
