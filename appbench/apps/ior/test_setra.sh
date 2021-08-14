#!/bin/bash

#if [ -z "$NVMBASE" ]; then
#    echo "PREFIX environment variable not defined. Have you ran setvars?"
#    echo "Dont forget to change \$VER in setvars.sh"
#    exit 1
#fi

APP="IOR"
APPDIR=$PWD
PREDICT=0
#RESULTS_FILE=$OUTPUTDIR/$APP/13Aug-ior-sensitest.txt
RESULTS_FILE=./13Aug-ior-sensitest.txt

KB=1024
MB=`echo "1024*$KB" | bc`
GB=`echo "1024*$MB" | bc`
NPROC=1
FILENAME="ior_test.dat"
TRANSFERSZ=`echo "4*$KB" | bc`
NR_READS=200 ##Number of TRANSFERSZ reads by each mpi proc per segment
BLOCKSIZE=`echo "$NR_READS*$TRANSFERSZ" | bc`
TOT_FILE_SIZE=`echo "30*$GB" | bc` #30GB
NR_SEGMENTS=0
echo "TotalFIle size" $TOT_FILE_SIZE
echo "BLOCKSIZE = " $BLOCKSIZE
DEV="/dev/sda4"

#declare -a setra=("256" "320" "512" "1024" "2048" "4096")
declare -a setra=("4096")
declare -a nproc=("1" "2" "4" "8" "16" "32")

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


for SETRA in "${setra[@]}"
do
    sudo blockdev --setra $SETRA $DEV
    for NPROC in "${nproc[@]}"
    do
        NR_SEGMENTS=`echo "$TOT_FILE_SIZE/($BLOCKSIZE*$NPROC)" | bc`
        PARAMS="-e -o=$FILENAME -b=$BLOCKSIZE -t=$TRANSFERSZ -s=$NR_SEGMENTS $FILEPERPROC $KEEPFILE"
        echo "NR_SEGMENTS=" $NR_SEGMENTS
        rm $FILENAME*

        mpirun -np $NPROC ior $WRITE $PARAMS

        FlushDisk

        echo "############################################################" >> $RESULTS_FILE
        sudo blockdev --getra $DEV >> $RESULTS_FILE
        $APPPREFIX mpirun -np $NPROC ior $READ $PARAMS $VERBOSE >> $RESULTS_FILE
    done
done
