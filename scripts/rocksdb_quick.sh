#!/bin/bash
cd $NVMBASE
#APP="db_bench.out"
#APP="fio.out"
APP="filebench.out"

SETUP(){
	$NVMBASE/scripts/clear_cache.sh
	cd $SHARED_LIBS/construct
	make clean
}

SETENV() {
	source scripts/setvars.sh
	$SCRIPTS/install_quartz.sh
	$SCRIPTS/throttle.sh
	$SCRIPTS/throttle.sh
}

SETUPEXTRAM() {
	$SCRIPTS/umount_ext4ramdisk.sh
	rm -rf  /mnt/ext4ramdisk/*
	rm -rf  /mnt/ext4ramdisk/
	sleep 5
	NUMAFREE=`numactl --hardware | grep "node 0 free:" | awk '{print $4}'`
	let DISKSZ=$NUMAFREE-5192
	echo $DISKSZ
	$SCRIPTS/umount_ext4ramdisk.sh
	$SCRIPTS/mount_ext4ramdisk.sh $DISKSZ
}

COMPILE_SHAREDLIB() {
	#Compile shared libs
	cd $SHARED_LIBS/construct
	make clean
	make CFLAGS=$DEPFLAGS
	sudo make install
}

RUNAPP() {
	#Run application
	cd $NVMBASE
	#$APPBENCH/apps/fio/run.sh &> $OUTPUTDIR/$OUTPUT
        #$APPBENCH/apps/rocksdb/run.sh &> $OUTPUTDIR/$OUTPUT
	$APPBENCH/apps/filebench/run.sh &> $OUTPUTDIR/$OUTPUT
	sudo dmesg -c &>> $OUTPUTDIR/$OUTPUT
}	


OUTPUTDIR=$APPBENCH/output
mkdir $OUTPUTDIR
#SETENV
#Don't do any migration
export APPPREFIX="numactl  --preferred=0"


mkdir $OUTPUTDIR/slowmem-migration-only
OUTPUT="slowmem-migration-only/$APP"
SETUP
make CFLAGS="-D_MIGRATE"
SETUPEXTRAM
RUNAPP
$SCRIPTS/clear_cache.sh
exit


mkdir $OUTPUTDIR/slowmem-obj-affinity
OUTPUT="slowmem-obj-affinity/$APP"
SETUP
make CFLAGS="-D_MIGRATE -D_OBJAFF"
SETUPEXTRAM
RUNAPP
$SCRIPTS/rocksdb_extract_result.sh
$SCRIPTS/clear_cache.sh


mkdir $OUTPUTDIR/naive-os-fastmem
OUTPUT="naive-os-fastmem/$APP"
SETUP
make CFLAGS=""
SETUPEXTRAM
RUNAPP
$SCRIPTS/rocksdb_extract_result.sh
$SCRIPTS/clear_cache.sh


mkdir $OUTPUTDIR/optimal-os-fastmem
export APPPREFIX="numactl --membind=0"
OUTPUT="optimal-os-fastmem/$APP"
SETUP
make CFLAGS="-D_DISABLE_HETERO"
$SCRIPTS/umount_ext4ramdisk.sh
sleep 5
$SCRIPTS/mount_ext4ramdisk.sh 24000
RUNAPP
$SCRIPTS/rocksdb_extract_result.sh
$SCRIPTS/clear_cache.sh


mkdir $OUTPUTDIR/slowmem-only
OUTPUT="slowmem-only/$APP"
SETUP
make CFLAGS="-D_SLOWONLY"
export APPPREFIX="numactl --membind=1"
$SCRIPTS/umount_ext4ramdisk.sh
sleep 5
$SCRIPTS/mount_ext4ramdisk.sh 24000
RUNAPP 
$SCRIPTS/rocksdb_extract_result.sh
$SCRIPTS/clear_cache.sh



#exit



#exit


#mkdir $OUTPUTDIR/fastmem-only
exit
#Disable hetero for fastmem only mode
#make CFLAGS="-D_DISABLE_HETERO"
