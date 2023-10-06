#/bin/bash
#set -x
./clearcache.sh && LD_PRELOAD=/usr/lib/lib_$1.so ./shared_bench DATA/shared_file 60000000000 16 $2 1 0 1
