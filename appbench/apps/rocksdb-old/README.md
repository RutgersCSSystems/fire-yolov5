## RocksDB: A Persistent Key-Value Store for Flash and RAM Storage

### Run Experiments
All the experiments are in the following folder.
this script needs to be updated to run different applications

```
cd ./scripts/run/run_all_variation.sh
```

## Running RocksDB: A Persistent Key-Value Store for Flash and RAM Storage

### Run rocksdb with or without using the new pread_ra syscall

To enable pread_ra syscall that is enabled for crossfs
```
//vim Makefile
//## add -DCROSSLAYER_SYSCALLS to CXXFLAGS (line 20)
//CXXFLAGS += ${EXTRA_CXXFLAGS} -DCROSSLAYER_SYSCALLS

vim build_tools/build_detect_platform
COMMON_FLAGS="$COMMON_FLAGS ${CFLAGS} -DCROSSLAYER_SYSCALLS"
./compile.sh
```

### Alternatively, navigate to RocksDB folder
To enable pread_ra syscall
```
cp build_tools/build_detect_platform_cross build_tools/build_detect_platform
./compile.sh
```

To disable pread_ra syscall
```
cp build_tools/build_detect_platform_orig build_tools/build_detect_platform
./compile.sh
```
