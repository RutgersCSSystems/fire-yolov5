#!/bin/bash
set -x
DBHOME=$PWD
PREDICT="OSONLY"
THREAD=16
VALUE_SIZE=4096
SYNC=0
KEYSIZE=100
WRITE_BUFF_SIZE=67108864
NUM=100000
DBDIR=$DBHOME/DATA

WORKLOADS="readreverse"
WRITEARGS="--benchmarks=fillseq --use_existing_db=0 --threads=1"
READARGS="--benchmarks=$WORKLOADS --use_existing_db=1 --mmap_read=0"
APPPREFIX="/usr/bin/time -v"

PARAMS="--db=$DBDIR --value_size=4096 --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=100 --write_buffer_size=67108864 --threads=$THREAD --num=$NUM"

FlushDisk()
{
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
	sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
	sudo sh -c "sync"
}

SETPRELOAD()
{
	if [[ "$PREDICT" == "LIBONLY" ]]; then 	
		#uses read_ra but disables OS prediction
		echo "setting LIBONLY pred"
		cp $DBHOME/build_tools/build_detect_platform_cross $DBHOME/build_tools/build_detect_platform
		$DBHOME/compile.sh &> compile.out
		export LD_PRELOAD=/usr/lib/libonlylibpred.so
	elif [[ "$PREDICT" == "CROSSLAYER" ]]; then
		#uses read_ra
		echo "setting CROSSLAYER pred"
		cp $DBHOME/build_tools/build_detect_platform_cross $DBHOME/build_tools/build_detect_platform
		$DBHOME/compile.sh &> compile.out
		export LD_PRELOAD=/usr/lib/libos_libpred.so

	elif [[ "$PREDICT" == "OSONLY" ]]; then 	
		#does not use read_ra and disables all application read-ahead
		echo "setting OS pred"
		cp $DBHOME/build_tools/build_detect_platform_orig $DBHOME/build_tools/build_detect_platform
		$DBHOME/compile.sh &> compile.out
		export LD_PRELOAD=/usr/lib/libonlyospred.so
	else [[ "$PREDICT" == "VANILLA" ]]; #does not use read_ra
		echo "setting VANILLA"
		cp $DBHOME/build_tools/build_detect_platform_orig $DBHOME/build_tools/build_detect_platform
		$DBHOME/compile.sh &> compile.out
		export LD_PRELOAD=""
	fi

}

BUILD_LIB()
{
	cd $SHARED_LIBS/pred
	./compile.sh
	cd $DBHOME
}

CLEAR_PWD()
{
	cd $DBDIR
	rm -rf *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
	cd ..
}


#Run write workload twice
#CLEAR_PWD
#$DBHOME/db_bench $PARAMS $WRITEARGS &> out.txt

echo "RUNNING CROSSLAYER.................."
FlushDisk
PREDICT="CROSSLAYER"
SETPRELOAD
$DBHOME/db_bench $PARAMS $READARGS
FlushDisk
export LD_PRELOAD=""
exit

FlushDisk
echo "RUNNING OSONLY.................."
PREDICT="OSONLY"
SETPRELOAD
$DBHOME/db_bench $PARAMS $READARGS
export LD_PRELOAD=""
FlushDisk

echo "RUNNING Vanilla.................."
FlushDisk
PREDICT="VANILLA"
SETPRELOAD
$DBHOME/db_bench $PARAMS $READARGS
FlushDisk
export LD_PRELOAD=""

#echo "RUNNING LIBONLY.................."
#FlushDisk
#PREDICT="LIBONLY"
#SETPRELOAD
#$DBHOME/db_bench $PARAMS $READARGS
#FlushDisk
#export LD_PRELOAD=""


exit


