#!/bin/bash
#set -x
cd $NVMBASE
APP=""
TYPE="NVM"
#TYPE="NVM"

SETUP(){
	$NVMBASE/scripts/clear_cache.sh
	cd $SHARED_LIBS/construct
	make clean
}

THROTTLE() {
	source scripts/setvars.sh
	cp $SCRIPTS/nvmemul-throttle.ini $QUARTZ/nvmemul.ini
	$SCRIPTS/install_quartz.sh
	#$SCRIPTS/throttle.sh
	#$SCRIPTS/throttle.sh
}

DISABLE_THROTTLE() {
	source scripts/setvars.sh
	cp $SCRIPTS/nvmemul-nothrottle.ini $QUARTZ/nvmemul.ini
	$SCRIPTS/throttle.sh
	#$SCRIPTS/throttle.sh
}


SETUPEXTRAM() {

	kill -9 `pidof neo4j`
	sudo killall java
	sudo kill -9 `pidof neo4j`
	sudo kill -9 `pidof postgres`
	sudo kilall postgres

	$SCRIPTS/umount_ext4ramdisk.sh
	rm -rf  /mnt/ext4ramdisk/*
	rm -rf  /mnt/ext4ramdisk/
	sleep 5
	NUMAFREE=`numactl --hardware | grep "node 0 free:" | awk '{print $4}'`
	let DISKSZ=$NUMAFREE-4096
	echo $DISKSZ
	$SCRIPTS/umount_ext4ramdisk.sh
	$SCRIPTS/mount_ext4ramdisk.sh $DISKSZ

	#Enable for Ramdisk
	if [ "NVM" = "$TYPE" ]
	then
		echo "Running for NVM"
		sudo ln -s /mnt/ext4ramdisk $APPBENCH/shared_data
	else
		#Enable for SSD
		echo "Running for SSD"
		mkdir $APPBENCH/shared_data
	fi
}

COMPILE_SHAREDLIB() {
	#Compile shared libs
	cd $SHARED_LIBS/construct
	make clean
	make CFLAGS=$DEPFLAGS
	sudo make install
}

#APP="rocksdb.out"
#APP="fio.out"
#APP="flashx.out"
#APP="filebench.out"
#APP="redis.out"
#APP=fxmark
#APP="flash.out"
APP="cassandra.out"


RUNAPP() {
	#Run application
	cd $NVMBASE

	#$APPBENCH/apps/fio/run.sh &> $OUTPUT

        #$APPBENCH/apps/rocksdb/run.sh &> $OUTPUT
	#$APPBENCH/redis-5.0.5/src/run.sh &> $OUTPUT
	#$APPBENCH/apps/filebench/run.sh &> $OUTPUT

        #$APPBENCH/apps/rocksdb/run_new.sh &> $OUTPUT
	#$APPBENCH/apps/FlashX/run.sh &> $OUTPUT
	#$APPBENCH/apps/filebench/run.sh &> $OUTPUTDIR/$OUTPUT
	#$APPBENCH/apps/pigz/run.sh &> $OUTPUT
	#$APPBENCH/apps/fxmark/run.sh &> $OUTPUT
	#$APPBENCH/redis-3.0.0/src/run.sh &> $OUTPUT

        cd $APPBENCH/butterflyeffect/code
	#source scripts/setvars.sh
	$APPBENCH/butterflyeffect/code/run.sh &> $OUTPUT

	sudo dmesg -c &>> $OUTPUT
}

SET_RUN_APP() {	
	BASE=$OUTPUTDIR
	mkdir $OUTPUTDIR/$1
	export OUTPUTDIR=$OUTPUTDIR/$1

	if [ "NVM" = "$TYPE" ]
	then
		echo "Running for NVM"
		OUTPUT="$OUTPUTDIR/$APP-NVM"
	else
		echo "Running for SSD"
		OUTPUT="$OUTPUTDIR/$APP-SSD"
	fi

        $NVMBASE/scripts/clear_cache.sh
        cd $SHARED_LIBS/construct
        make clean
	make CFLAGS="$2"
	sudo make install

	RUNAPP
	$SCRIPTS/rocksdb_extract_result.sh
	$SCRIPTS/clear_cache.sh
	export OUTPUTDIR=$BASE
	set +x
}

OUTPUTDIR=$APPBENCH/output
mkdir -f $OUTPUTDIR



if [ -z "$1" ]
  then
    THROTTLE
  else
    echo "Don't throttle"
fi

$SCRIPTS/umount_ext4ramdisk.sh
sleep 5
$SCRIPTS/mount_ext4ramdisk.sh 24000
DISABLE_THROTTLE
export APPPREFIX="numactl --membind=0"
#SET_RUN_APP "optimal-os-fastmem-$TYPE" "-D_DISABLE_HETERO  -D_DISABLE_MIGRATE"
exit


export APPPREFIX="numactl --membind=1"
$SCRIPTS/umount_ext4ramdisk.sh
sleep 5
$SCRIPTS/mount_ext4ramdisk.sh 24000
SET_RUN_APP "slowmem-only-$TYPE" "-D_SLOWONLY -D_DISABLE_MIGRATE"
exit



export APPPREFIX="numactl --preferred=0"
SETUPEXTRAM
SET_RUN_APP "naive-os-fastmem-$TYPE" "-D_DISABLE_MIGRATE"
exit


export APPPREFIX="numactl  --preferred=0"
SETUPEXTRAM
SET_RUN_APP "slowmem-obj-affinity-nomig-$TYPE" "-D_DISABLE_MIGRATE -D_OBJAFF"
exit

export APPPREFIX="numactl  --preferred=0"
SETUPEXTRAM
SET_RUN_APP "slowmem-migration-only-$TYPE" "-D_MIGRATE"
exit





export APPPREFIX="numactl  --preferred=0"
SETUPEXTRAM
SET_RUN_APP "slowmem-obj-affinity-$TYPE" "-D_MIGRATE -D_OBJAFF"




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
exit

#Don't do any migration




#mkdir $OUTPUTDIR/fastmem-only
exit
#Disable hetero for fastmem only mode
#make CFLAGS="-D_DISABLE_HETERO"
