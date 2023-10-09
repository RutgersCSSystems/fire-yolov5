#/bin/bash
#set -x
./clearcache.sh && LD_PRELOAD=/usr/lib/lib_$1.so ./private_bench DATA/private_file 10000000000 16 65536 0 1 0
#./clearcache.sh && LD_PRELOAD=/usr/lib/lib_$1.so ./shared_bench DATA/shared_file 60000000000 16 4096 0 1 1
