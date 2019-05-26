#!/bin/bash
cd $NVMBASE


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
	$APPBENCH/apps/rocksdb/run.sh &> $OUTPUTDIR/$OUTPUT
	sudo dmesg -c &>> $OUTPUTDIR/$OUTPUT
}	


OUTPUTDIR=$APPBENCH/output

mkdir $OUTPUTDIR
#SETENV
#Don't do any migration
export APPPREFIX="numactl  --preferred=0"
mkdir $OUTPUTDIR/naive-os-fastmem
OUTPUT="naive-os-fastmem/db_bench.out"
SETUP
make CFLAGS=""
RUNAPP
$SCRIPTS/rocksdb_extract_result.sh
exit


mkdir $OUTPUTDIR/optimal-os-fastmem
export APPPREFIX="numactl --membind=0"
OUTPUT="optimal-os-fastmem/db_bench.out"
SETUP
make CFLAGS="-D_DISABLE_HETERO"
RUNAPP
exit




mkdir $OUTPUTDIR/slowmem-only
OUTPUT="slowmem-only/db_bench.out"
SETUP
make CFLAGS="-D_SLOWONLY"
export APPPREFIX="numactl --membind=1"
RUNAPP 
$SCRIPTS/rocksdb_extract_result.sh
exit









mkdir $OUTPUTDIR/slowmem-migration-only
OUTPUT="slowmem-migration-only/db_bench.out"
SETUP
make CFLAGS="-D_MIGRATE"
RUNAPP
exit



mkdir $OUTPUTDIR/slowmem-obj-affinity
OUTPUT="slowmem-obj-affinity/db_bench.out"
SETUP
make CFLAGS="-D_MIGRATE -D_OBJAFF"
RUNAPP

#exit



#exit


#mkdir $OUTPUTDIR/fastmem-only
exit
#Disable hetero for fastmem only mode
#make CFLAGS="-D_DISABLE_HETERO"
