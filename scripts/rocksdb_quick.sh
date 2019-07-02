#!/bin/bash
#set -x

cd $NVMBASE
#APP="db_bench.out"
#APP="fio.out"
#APP="filebench.out"
APP="redis.out"


SETUP(){
	$NVMBASE/scripts/clear_cache.sh
	cd $SHARED_LIBS/construct
	make clean
}

SETENV() {
	source scripts/setvars.sh
	$SCRIPTS/install_quartz.sh
	#$SCRIPTS/throttle.sh
	#$SCRIPTS/throttle.sh
}

SETUPEXTRAM() {
	$SCRIPTS/umount_ext4ramdisk.sh
	rm -rf  /mnt/ext4ramdisk/*
	rm -rf  /mnt/ext4ramdisk/
	sleep 5
	NUMAFREE=`numactl --hardware | grep "node 0 free:" | awk '{print $4}'`
	let DISKSZ=$NUMAFREE-3192
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
	#$APPBENCH/apps/filebench/run.sh &> $OUTPUTDIR/$OUTPUT

	#$APPBENCH/redis-5.0.5/src/run.sh &> $OUTPUT
	$APPBENCH/redis-3.0.0/src/run.sh &> $OUTPUT
	sudo dmesg -c &>> $OUTPUT
}

OUTPUTDIR=$APPBENCH/output
mkdir $OUTPUTDIR

SET_RUN_APP() {	
	BASE=$OUTPUTDIR
	mkdir $OUTPUTDIR/$1
	export OUTPUTDIR=$OUTPUTDIR/$1
	OUTPUT="$OUTPUTDIR/$APP"

        $NVMBASE/scripts/clear_cache.sh
        cd $SHARED_LIBS/construct
        make clean
	make CFLAGS="$2"

	SETUPEXTRAM
	RUNAPP
	$SCRIPTS/rocksdb_extract_result.sh
	$SCRIPTS/clear_cache.sh
	export OUTPUTDIR=$BASE
	set +x
}

SETENV

export APPPREFIX="numactl --preferred=0"
SET_RUN_APP "slowmem-migration-only" "-D_MIGRATE"

export APPPREFIX="numactl --preferred=0"
SET_RUN_APP "slowmem-obj-affinity" "-D_MIGRATE -D_OBJAFF"
exit

export APPPREFIX="numactl --preferred=0"
SET_RUN_APP "naive-os-fastmem" "-D_DISABLE_MIGRATE"
exit



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
