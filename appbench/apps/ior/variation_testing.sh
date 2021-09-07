#!/bin/bash

##For a given IOR configuration, plot bandwidth and runtime wrt prediction and setra

APPPREFIX="/usr/bin/time -v"
TODAY=`date +'%d-%B'` ##todays date
KB=1024
MB=`echo "1024*$KB" | bc`
GB=`echo "1024*$MB" | bc`
PAGE_SZ=`echo "4*$KB" | bc`
BLOCK_SZ=512 #512 bytes
INTMAX=2147483647

DEV="/dev/loop0"
FILENAME="/mnt/ext4ramdisk/ior_test.dat"
OUTFOLDER="$PWD/ramdisk-analysis"
mkdir $OUTFOLDER

APP="IOR"
PREDICT=0
NPROC=32
NR_REPEATS=10

NR_READS=200 ##Number of TRANSFERSZ reads by each mpi proc per segment
TRANSFERSZ=`echo "1*$MB" | bc` #1M
BLOCKSIZE=`echo "$NR_READS*$TRANSFERSZ" | bc`
TOT_FILE_SIZE=`echo "120*$GB" | bc` #120GB
NR_SEGMENTS=`echo "$TOT_FILE_SIZE/($BLOCKSIZE*$NPROC)" | bc`


declare -a setra=("256" "512" "1024" "2048" "4096" "8192" "16384" "2147483640")
declare -a predict=("0" "1")

BW_PLOT_FILE=${OUTFOLDER}/$TODAY-$APP-BW-seqread-diff-file-${NPROC}_proc-120G_fsize-1M_tsize.dat
RT_PLOT_FILE=${OUTFOLDER}/$TODAY-$APP-RT-seqread-diff-file-${NPROC}_proc-120G_fsize-1M_tsize.dat

#########################################################################
FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sleep 2
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

mount_extr4ramdisk() {

    let scount="$1*1024" #GB
    sudo umount /mnt/ext4ramdisk
    sudo umount /mnt/ramdisk

    sudo rm -rf /mnt/ramdisk/ext4.image

    sudo mkdir /mnt/ramdisk
    sudo mount -t ramfs ramfs /mnt/ramdisk
    sudo dd if=/dev/zero of=/mnt/ramdisk/ext4.image bs=1M count=$scount
    sudo mkfs.ext4 -F /mnt/ramdisk/ext4.image

    sudo mkdir /mnt/ext4ramdisk
    sudo mount -o loop /mnt/ramdisk/ext4.image /mnt/ext4ramdisk
    sudo chown -R $USER /mnt/ext4ramdisk
}

umount_ext4ramdisk() {
    sudo umount /mnt/ext4ramdisk
    sudo rm -rf /mnt/ramdisk/ext4.image
    sudo umount /mnt/ramdisk
}
#########################################################################

#IOR flags
VERBOSE="-v"
REORDER="-C"
FILEPERPROC="-F"
KEEPFILE="-k"
WRITE=" -w "
READ=" -r "


mount_extr4ramdisk 130

echo "RASIZE,pred-min,pred,pred-max,nopred-min,nopred,nopred-max" > $BW_PLOT_FILE
echo "RASIZE,pred-min,pred,pred-max,nopred-min,nopred,nopred-max" > $RT_PLOT_FILE

PARAMS="-e -o=$FILENAME -b=$BLOCKSIZE -t=$TRANSFERSZ -s=$NR_SEGMENTS $FILEPERPROC $KEEPFILE"

echo "Starting write load"
rm $FILENAME*
mpirun -np $NPROC ior $WRITE $PARAMS &> /dev/null
echo "Done write load"

for SETRA in "${setra[@]}" #For each setra size
do
    echo "Starting SETRA = $SETRA"
    SETRA_PAGES=`echo "($SETRA*$BLOCK_SZ)/$PAGE_SZ" | bc`
    echo -n "$SETRA_PAGES" >> $BW_PLOT_FILE
    echo -n "$SETRA_PAGES" >> $RT_PLOT_FILE

    sudo blockdev --setra $SETRA $DEV

    for PREDICT in "${predict[@]}"
    do
	echo "Starting Predict = $PREDICT"
        min_bw=100000000
        max_bw=0
        avg_bw=0
        this_bw=0

        min_rt=100000000
        max_rt=0
        avg_rt=0
        this_rt=0
        for NR in $(seq 1 1 $NR_REPEATS)
        do
            ###############################################################
            FlushDisk
            SETPRELOAD
            $APPPREFIX mpirun -np $NPROC ior $READ $PARAMS $VERBOSE &> tmp
            export LD_PRELOAD=""
            ###############################################################

            this_bw=`echo tmp | grep "Max Read" | awk '{print $3}'`
            ##########################
            min_bw=$(min_number $this_bw $min_bw)
            max_bw=$(max_number $this_bw $max_bw)
            avg_bw=`echo "scale=2; $avg_bw + $this_bw" | bc -l`
            ##########################

            this_rt=`echo tmp | grep "Elapsed" | awk '{print $8}' | awk -F":" '{print $1*60 +$2}'` #time in mins
            ##########################
            min_rt=$(min_number $this_rt $min_rt)
            max_rt=$(max_number $this_rt $max_rt)
            avg_rt=`echo "scale=2; $avg_rt + $this_rt" | bc -l`
            ##########################        
        done
        avg_bw=`echo "scale=2; $avg_bw/$NR_REPEATS" | bc -l`
        echo -n ",$min_bw,$avg_bw,$max_bw" >> $BW_PLOT_FILE
        
        avg_rt=`echo "scale=2; $avg_rt/$NR_REPEATS" | bc -l`
        echo -n ",$min_rt,$avg_rt,$max_rt" >> $RT_PLOT_FILE
    done
    echo >> $BW_PLOT_FILE
    echo >> $RT_PLOT_FILE
done
