#!/bin/bash
cd $NVMBASE


SETUP(){
	scripts/clear_cache.sh
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
	$APPBENCH/apps/rocksdb/run.sh
}


#SETENV

mkdir $OUTPUTDIR/slowmem-migration-only
OUTPUT="slowmem-migration-only/db_bench.out"
SETUP
make CFLAGS="-D_MIGRATE"
export APPPREFIX="numactl --preferred=1"
RUNAPP &> $OUTPUTDIR/$OUTPUT

mkdir $OUTPUTDIR/slowmem-obj-affinity
OUTPUT="slowmem-obj-affinity/db_bench.out"
SETUP
make CFLAGS="-D_MIGRATE -D_OBJAFF"
export APPPREFIX="numactl --preferred=1"
RUNAPP &> $OUTPUTDIR/$OUTPUT

#Don't do any migration
mkdir $OUTPUTDIR/naive-os-fastmem
OUTPUT="naive-os-fastmem/db_bench.out"
SETUP
make CFLAGS=""
export APPPREFIX="numactl --preferred=1"
RUNAPP &> $OUTPUTDIR/$OUTPUT

mkdir $OUTPUTDIR/slowmem-only
OUTPUT="slowmem-only/db_bench.out"
SETUP
make CFLAGS="-D_SLOWONLY"
export APPPREFIX="numactl --membind=1"
RUNAPP &> $OUTPUTDIR/$OUTPUT

#mkdir $OUTPUTDIR/fastmem-only
exit


#Disable hetero for fastmem only mode
#make CFLAGS="-D_DISABLE_HETERO"
