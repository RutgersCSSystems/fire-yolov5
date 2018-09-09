200#!/bin/bash
set -x

#OUTPUT=$1
LEVELDBHOME=/users/skannan/ssd/schedsp/leveldb-nvm
DBDIR=/mnt/pmemdir
LEVELDBVANILLAHOME=$LEVELDBHOME/leveldb_vanilla
OUTPUTDIR=$LEVELDBHOME/scripts/output-graphs/2017-03-31/LLC
OUTPUT=$OUTPUTDIR/out.txt
#BENCHMARKS="--benchmarks=fillrandom,readrandom,stats"
BENCHMARKS="--benchmarks=fillrandom,stats"
#export PREFIX="/users/skannan/ssd/schedsp/linux-4.5.4/tools/perf/perf stat -e instructions -e LLC-store-misses -e LLC-load-misses"

let NUMTHREADS=1
let WORKLOAD=1000000
let VALUESZ=1024
let BUFFERSZ=1024
let APPTHREADS=1
OPERATION="store"

mkdir -p $OUTPUTDIR
export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
source ~/.bashrc

COMPILE() {
make -j8
}

CLEAN(){
rm -rf $DBDIR/*
}

TAKEREST(){
   sleep 10
}

ROCKSDB="/users/skannan/ssd/schedsp/apps/rocksdb"
USEPLAINTABLE="--use_plain_table=1"
DISABLEDATASYNC="--disable_data_sync=0"

RocksDB() {

	STOREOUTPUT=$OUTPUTDIR/"store_valusez_"$VALUESZ"_novelsm_"$WORKLOAD".out"
	OTHERPARAMS="--write_buffer_size=209715200" #"--statistics=0 --stats_per_interval=0 --stats_interval=1048576 --histogram=0"
	VALSIZE="--value_size=$VALUESZ"
	STORAGE=$DBDIR
	NUMVALS="--num=$WORKLOAD"
	BENCHMARKS="--benchmarks=filluniquerandom"

	rm -rf $STOREOUTPUT
	$PREFIX $ROCKSDB/db_bench --db=$STORAGE/rocksdb --key_size=100 --prefix_size=12 --keys_per_prefix=10 --compression_type=none --compression_ratio=1 --min_level_to_compress=-1 --disable_seek_compaction=1 --hard_rate_limit=2 --level0_file_num_compaction_trigger=8 --target_file_size_base=134217728 --max_bytes_for_level_base=1073741824 --disable_wal=0 --wal_dir=$STORAGE/0_WAL_LOG --sync=0 --verify_checksum=1 --delete_obsolete_files_period_micros=314572800 --max_background_compactions=4 --max_background_flushes=0 --level0_slowdown_writes_trigger=16 --level0_stop_writes_trigger=24 --mmap_read=1 --mmap_write=0 --memtablerep=prefix_hash --bloom_bits=10 --bloom_locality=1 $BENCHMARKS --use_existing_db=0 --threads=1 $USEPLAINTABLE $OTHERPARAMS $NUMVALS $VALSIZE &> $STOREOUTPUT

}



#Serial read threads
NoveLSM-NVM() {
  export TEST_TMPDIR=$DBDIR
  STOREOUTPUT=$OUTPUTDIR/"store_valusez_"$VALUESZ"_novelsm_"$WORKLOAD".out"
  rm $STOREOUTPUT
  echo "*************"
  echo $STOREOUTPUT
  rm -rf $STOREOUTPUT
  OTHERPARAMS="--threads=$APPTHREADS --write_buffer_size=200 --write_buffer_size_2=$BUFFERSZ --num_levels=2 --num_read_threads=0" 
  $PREFIX $LEVELDBHOME/out-static/db_bench --value_size=$VALUESZ $BENCHMARKS --num=$WORKLOAD $OTHERPARAMS &> $STOREOUTPUT
  echo "*************"
}

#Parallel read threads
NoveLSM-NVM-parallel() {
  export TEST_TMPDIR=$DBDIR
  STOREOUTPUT=$OUTPUTDIR/"store_valusez_"$VALUESZ"_novelsm_"$WORKLOAD".out"
  rm $STOREOUTPUT
  echo "*************"
  echo $STOREOUTPUT
  rm -rf $STOREOUTPUT
  OTHERPARAMS="--threads=$APPTHREADS --write_buffer_size=200 --write_buffer_size_2=$BUFFERSZ --num_levels=2 --num_read_threads=1" 
  $PREFIX $LEVELDBHOME/out-static/db_bench --value_size=$VALUESZ $BENCHMARKS --num=$WORKLOAD $OTHERPARAMS &> $STOREOUTPUT
  echo "*************"
}

#Parallel read threads
NoveLSM-NVM-parallel-NoSST() {
  export TEST_TMPDIR=$DBDIR
  STOREOUTPUT=$OUTPUTDIR/"store_valusez_"$VALUESZ"_novelsm_"$WORKLOAD".out"
  rm $STOREOUTPUT
  echo "*************"
  echo $STOREOUTPUT
  rm -rf $STOREOUTPUT
  BUFFERSZ=8192
  OTHERPARAMS="--threads=$APPTHREADS --write_buffer_size=200 --write_buffer_size_2=$BUFFERSZ --num_levels=2 --num_read_threads=1" 
  $PREFIX $LEVELDBHOME/out-static/db_bench --value_size=$VALUESZ $BENCHMARKS --num=$WORKLOAD $OTHERPARAMS &> $STOREOUTPUT
  echo "*************"
}


RUN_LEVELDB_VANILLA() {
  export TEST_TMPDIR=$DBDIR
  STOREOUTPUT=$OUTPUTDIR/"store_valusez_"$VALUESZ"_vanilla_"$WORKLOAD".out"
  rm $STOREOUTPUT
  OTHERPARAMS="--write_buffer_size=209715200" 
  echo "*************"
  echo $STOREOUTPUT
  rm -rf $STOREOUTPUT
  $PREFIX $LEVELDBVANILLAHOME/out-static/db_bench --threads=$APPTHREADS  --value_size=$VALUESZ $BENCHMARKS --num=$WORKLOAD $OTHERPARAMS &> $STOREOUTPUT
  echo "*************"
}


RUN_LEVELDB_VANILLA_BUFFERSZ() {
  cd $LEVELDBVANILLAHOME
  STOREOUTPUT=$OUTPUTDIR/"store_valusez_"$VALUESZ"_vanilla_"$WORKLOAD"_buffer_"$BUFFERSZ".out"
  $LEVELDBVANILLAHOME/out-static/db_bench --threads=1  --value_size=$VALUESZ --benchmarks=fillrandom,readrandom --num=$WORKLOAD --write_buffer_size=$BUFFERSZ &> $STOREOUTPUT
}

#ASSUME WORKLOAD AND NUMTHREADS PARAMS are set
RUNALONE() {
	CLEAN
	#RUN_LEVELDB
	#RUN_YCSB
        #CLEAN 
}

EXTRACT(){

    rm -rf "threads_"*
    rm -rf "vanilla.out"

    for NUMTHREADS in 0 1
    do
	for BUFFERSZ in 800 1000 500 100
	do

 	  for VALUESZ in 1024 4096 8192 16384 32768 65536 131072
   	  do

           OUT="threads_"$NUMTHREADS"buffersz_"$BUFFERSZ".out"
          for f in $(find . -name $OPERATION"_valusez_"$VALUESZ'*'$NUMTHREADS"thread_"'*'"_buffer_"$BUFFERSZ".out"); do grep -r "micros" $f | tail -1; done &>> $OUT 
      done
    done
 done

	for VALUESZ in 1024 4096 8192 16384 32768 65536 131072
	do
   		VANILLAOUT="vanilla.out"
  		for f in $(find . -name $OPERATION"_valusez_"$VALUESZ"_vanilla_"'*'".out"); do grep -r "micros/op;" $f | tail -1; done &>> $VANILLAOUT 
	done
}







CONSOLIDATE(){

    for BUFFERSZ in 800 1000 500 100
     do
	for VALUESZ in 65536 131072 16384 32768 1024 4096 8192
	do
      paste -d, "Valuesz_"$VALUESZ"_vanilla_"'*' "Valuesz_"$VALUESZ"_threads_"[0-1]"buffersz_"$BUFFERSZ".out" >> "result-"$VALUESZ".csv"
      rm "Valuesz_"$VALUESZ"_threads_"[0-1]"buffersz_"$BUFFERSZ".out"
      done
    done
}


#for BUFFERSZ in 800 #100 #1000 500 100
#do
#for NUMTHREADS in 0 1
#do


Run_RocksDB() {

	let WORKLOAD=4000000
	for VALUESZ in 1024 4096 16384 65536 262144
	do
	   CLEAN 
	   RocksDB
	   WORKLOAD=$((WORKLOAD/4))
	   echo $WORKLOAD
	 done
}


Run_NoveLSM-NVM-parallel() {

	let WORKLOAD=4000000

	for VALUESZ in 1024 4096 16384 65536 262144
	do
	   CLEAN 
	   NoveLSM-NVM-parallel
	   WORKLOAD=$((WORKLOAD/4))
	   echo $WORKLOAD
	 done
}


Run_NoveLSM-NVM() {

	let WORKLOAD=4000000

	for VALUESZ in 1024 4096 16384 65536 262144
	do
	   CLEAN 
	   NoveLSM-NVM
	   WORKLOAD=$((WORKLOAD/4))
	   echo $WORKLOAD
	 done
}


Run_NoveLSM-NVM-parallel-NoSST() {

	let WORKLOAD=4000000
	for VALUESZ in 1024 4096 16384 65536 262144
	do
	   CLEAN 
	   NoveLSM-NVM-parallel-NoSST
	   WORKLOAD=$((WORKLOAD/4))
	   echo $WORKLOAD
	 done
}



RUNVANILLA() {

	let WORKLOAD=4000000
	for VALUESZ in 1024 4096 16384 65536 262144
	do
	   CLEAN 
	   RUN_LEVELDB_VANILLA
	   #RUN_LEVELDB_VANILLA_BUFFERSZ
	   WORKLOAD=$((WORKLOAD/4))
	   echo $WORKLOAD
	 done
}


#OPERATION="overwrite"
OPERATION="store"
#RUNALONE
#cd $OUTPUTDIR
#EXTRACT
#exit
#CONSOLIDATE

#cd $LEVELDBVANILLAHOME
#COMPILE
#RUNVANILLA
#CLEAN

cd $LEVELDBHOME
COMPILE

OUTPUTDIR=$LEVELDBHOME/scripts/output-graphs/2017-03-31/NoveLSM-NVM
mkdir -p $OUTPUTDIR
Run_NoveLSM-NVM
exit


OUTPUTDIR=$LEVELDBHOME/scripts/output-graphs/2017-03-31/NoveLSM-NVM-parallel
mkdir -p $OUTPUTDIR
Run_NoveLSM-NVM-parallel


OUTPUTDIR=$LEVELDBHOME/scripts/output-graphs/2017-03-31/NoveLSM-NVM-parallel-NoSST
mkdir -p $OUTPUTDIR
Run_NoveLSM-NVM-parallel-NoSST
exit


OUTPUTDIR=$LEVELDBHOME/scripts/output-graphs/2017-03-31/RocksDB
mkdir -p $OUTPUTDIR
Run_RocksDB
#EXTRACT
#CONSOLIDATE
exit
