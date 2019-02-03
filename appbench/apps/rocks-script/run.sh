set -x
ROCKSDB="$APPBENCH/apps/rocksdb/"
USEPLAINTABLE="--use_plain_table=1"
DISABLEDATASYNC="--disable_data_sync=0"
STORAGE="$APPBENCH/apps/rocksdb/DATA"
mkdir $STORAGE
#OTHERPARAMS=" --key_size=100 --prefix_size=12 --keys_per_prefix=10 --compression_type=none --min_level_to_compress=-1 --disable_seek_compaction=1 --level0_file_num_compaction_trigger=8 --disable_wal=0 --wal_dir=$STORAGE/0_WAL_LOG --sync=0 --verify_checksum=1 --max_background_compactions=4 --max_background_flushes=0 --level0_slowdown_writes_trigger=16 --level0_stop_writes_trigger=24 --mmap_read=1 --mmap_write=0 --bloom_bits=10 --bloom_locality=1 --write_buffer_size=67108864 --use_existing_db=0 --threads=1 --use_cuckoo_table=1 --cuckoo_hash_ratio=0.9"

OTHERPARAMS=" --num_levels=2 --compression_type=none --disable_auto_compactions --threads=4 --write_buffer_size=104857600"

#YCSBTRACE=" --run_trace_path=/mnt/ramdisk/workloade_run_trace.out --load_trace_path=/mnt/ramdisk/workloade_load_trace.out"
BENCHMARK=" --benchmarks=fillrandom,readrandom,fillseq,readseq"
#BENCHMARK=" --benchmarks=loadycsb,runycsb"
rm $STORAGE/*
NUMVALS=" --num=1000000"
VALSIZE=" --value_size=4096"

#Delete the existing DB
rm -rf $STORAGE/rocksdb

export LD_PRELOAD=$SHARED_LIBS/construct/libmigration.so
$APPPREFIX $ROCKSDB/db_bench --db=$STORAGE/rocksdb $OTHERPARAMS $NUMVALS $VALSIZE $BENCHMARK #$YCSBTRACE
export LD_PRELOAD=""
exit
