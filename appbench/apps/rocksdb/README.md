## RocksDB: A Persistent Key-Value Store for Flash and RAM Storage


# Run rocksdb without using the new pread_ra syscall

```
vim Makefile
## add -DCROSSLAYER_SYSCALLS to CXXFLAGS (line 20)
CXXFLAGS += ${EXTRA_CXXFLAGS} -DCROSSLAYER_SYSCALLS
./compile.sh
```

