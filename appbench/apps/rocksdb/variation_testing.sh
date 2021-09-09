#!/bin/bash

##For a given rocksdb configuration, plot bandwidth and runtime wrt prediction and setra

APPPREFIX="/usr/bin/time -v"
TODAY=`date +'%d-%B'` ##todays date
KB=1024
MB=`echo "1024*$KB" | bc`
GB=`echo "1024*$MB" | bc`
PAGE_SZ=`echo "4*$KB" | bc`
BLOCK_SZ=512 #512 bytes
INTMAX=2147483647

DEV="/dev/sda4"

OUTFOLDER="$PWD/ssd_c220g5-analysis"
mkdir $OUTFOLDER

APP="ssd_orignix_rocksdb"
NR_REPEATS=10

###ROCKSDB params
PREDICT=0
DBHOME=$PWD
THREAD=8
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
NUM=1000000
DBDIR=$DBHOME/DATA
WRITEARGS="--benchmarks=fillrandom --use_existing_db=0 --threads=1"
PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --threads=$THREAD --num=$NUM"
###############


declare -a setra=("256" "1024" "2048" "4096" "16384" "32768" "65536" "131072") #in nr_512byte_blocks
declare -a predict=("0") #disable predictor
declare -a workloads=("readseq" "readrandom")


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
		#export LD_PRELOAD=/usr/lib/libnopred.so
		#do nothing for now
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

#BUILD_LIB

#mount_extr4ramdisk 130



echo "Starting write load"
pushd $DBDIR
rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
popd
$DBHOME/db_bench $PARAMS $WRITEARGS 
echo "Done write load"


for WORKLOAD in "${workloads[@]}"
do
	BW_PLOT_FILE=${OUTFOLDER}/$TODAY-$APP-BW-$WORKLOAD-${THREAD}_proc.dat
	RT_PLOT_FILE=${OUTFOLDER}/$TODAY-$APP-RT-$WORKLOAD-${THREAD}_proc.dat
	echo "RASIZE,nopred-min,nopred,nopred-max" > $BW_PLOT_FILE
	echo "RASIZE,nopred-min,nopred,nopred-max" > $RT_PLOT_FILE

	READARGS="--benchmarks=$WORKLOAD --use_existing_db=1 --mmap_read=0"

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
				$APPPREFIX $DBHOME/db_bench $PARAMS $READARGS &> tmp
				export LD_PRELOAD=""
				###############################################################

				this_bw=`cat tmp | grep "$WORKLOAD" | head -1 | awk '{print $7}'`
				##########################
				min_bw=$(min_number $this_bw $min_bw)
				max_bw=$(max_number $this_bw $max_bw)
				avg_bw=`echo "scale=2; $avg_bw + $this_bw" | bc -l`
				##########################

				this_rt=`cat tmp | grep "Elapsed" | awk '{print $8}' | awk -F":" '{print $1*60 +$2}'` #time in secs
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
done
