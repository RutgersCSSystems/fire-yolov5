#!/bin/bash

#if [ -z "$NVMBASE" ]; then
#    echo "PREFIX environment variable not defined. Have you ran setvars?"
#    echo "Dont forget to change \$VER in setvars.sh"
#    exit 1
#fi

APP="IOR"
APPDIR=$PWD
PREDICT=0

KB=1024
MB=`echo "1024*$KB" | bc`
GB=`echo "1024*$MB" | bc`
NPROC=1
FILENAME="/mnt/ext4ramdisk/ior_test.dat"
OUTFOLDER="$PWD/ramdisk-analysis"
mkdir $OUTFOLDER
NR_READS=200 ##Number of TRANSFERSZ reads by each mpi proc per segment
TRANSFERSZ=`echo "4*$KB" | bc` #4K
BLOCKSIZE=`echo "$NR_READS*$TRANSFERSZ" | bc`
TOT_FILE_SIZE=`echo "30*$GB" | bc` #30GB
NR_SEGMENTS=0
echo "TotalFile size" $TOT_FILE_SIZE
echo "BLOCKSIZE = " $BLOCKSIZE
DEV="/dev/loop0"

declare -a setra=("256" "512" "1024" "2048" "4096" "8192" "16384")
declare -a nproc=("16" "32")
#declare -a transfersz=("4096" "32768" "131072" "1048576") #4K, 32K, 128K, 1M
#declare -a transfersz=("4" "32" "128" "1024") #4K, 32K, 128K, 1M
declare -a transfersz=("4") #4K, 32K, 128K, 1M
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
    for TXSZ in "${transfersz[@]}"
    do
        TRANSFERSZ=`echo "$TXSZ*$KB" | bc`
        BLOCKSIZE=`echo "$NR_READS*$TRANSFERSZ" | bc`
        NR_SEGMENTS=`echo "$TOT_FILE_SIZE/($BLOCKSIZE*$NPROC)" | bc`
        RESULTS_FILE=${OUTFOLDER}/19Aug-ior-sensitest-${TXSZ}K_reads-diff-file-${NPROC}-proc.txt
        #RESULTS_FILE=${OUTFOLDER}/19Aug-ior-sensitest-${TXSZ}K_reads-diff-file-${NPROC}-proc.txt
        for SETRA in "${setra[@]}"
        do
            sudo blockdev --setra $SETRA $DEV
            rm $FILENAME*
            PARAMS="-e -o=$FILENAME -b=$BLOCKSIZE -t=$TRANSFERSZ -s=$NR_SEGMENTS $FILEPERPROC $KEEPFILE"

            #####################################################
            mpirun -np $NPROC ior $WRITE $PARAMS
            FlushDisk
            #####################################################

            echo "############################################################" >> $RESULTS_FILE
            echo -n "RA_SIZE= " >> $RESULTS_FILE
            sudo blockdev --getra $DEV >> $RESULTS_FILE
            $APPPREFIX mpirun -np $NPROC ior $READ $PARAMS $VERBOSE &>> $RESULTS_FILE
        done
    done
done
