#/bin/bash
#set -x
./clearcache.sh && LD_PRELOAD=/usr/lib/lib_$1.so ./private_bench DATA/private_file 10000000000 16 $2 0 0 0
