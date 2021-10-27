## RocksDB: A Persistent Key-Value Store for Flash and RAM Storage


# Run rocksdb without using the new pread_ra syscall

vim env/io_posix.cc

in PosixRandomAccessFile::Prefetch() -> uncomment the readahead command

in PosixRandomAccessFile::Read() -> 

    r = syscall(449, fd_, ptr, left, static_cast<off_t>(offset), opts.ra_offset, opts.ra_bytes);
becomes
    r = syscall(449, fd_, ptr, left, static_cast<off_t>(offset), opts.ra_offset, 0);
