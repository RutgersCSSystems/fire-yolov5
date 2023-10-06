#/bin/bash
#set -x
./clearcache.sh && LD_PRELOAD=/usr/lib/lib_$1.so ./shared_bench DATA/shared_file 10000000000 16 $2 0 0 1
