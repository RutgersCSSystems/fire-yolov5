#/bin/bash
#set -x
./clearcache.sh && LD_PRELOAD=/usr/lib/lib_$1.so ./bench DATA/file1 60000000000 16 4096 0 0
